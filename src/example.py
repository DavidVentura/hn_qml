import time
import json
import os
import queue
import html
import threading

import requests

from typing import List, NamedTuple
from concurrent.futures import ThreadPoolExecutor

import pyotherside

session = requests.Session()
NUM_BG_THREADS = 2

comment_q = queue.Queue()
thread_q = queue.Queue()
THREAD_CACHE = {}

Comment = NamedTuple(
    "Comment",
    [
        ("thread_id", str),
        ("parent_id", str),
        ("comment_id", str),
        ("user", str),
        ("markup", str),
        ("kids", List[int]),
        ("dead", bool),
        ("deleted", bool),
        ("age", str),
        ("depth", int),
        ("threadVisible", bool),
        ("initialized", bool),
    ],
)
Story = NamedTuple(
    "Story",
    [
        ("story_id", str),
        ("title", str),
        ("url", str),
        ("url_domain", str),
        ("kids", List[int]),
        ("comment_count", int),
        ("score", int),
        ("initialized", bool),
    ],
)

def do_work():
    while True:
        if not comment_q.empty():
            c = comment_q.get()
            get_comment_and_submit(*c)
            continue
        if not thread_q.empty():
            t = thread_q.get()
            fetch_and_signal(t)
            continue
        time.sleep(0.05)

for i in range(NUM_BG_THREADS):
    t = threading.Thread(target=do_work)
    t.daemon = True
    t.start()

def fetch_and_signal(_id):
    data = get_story(_id)
    pyotherside.send("thread-pop", _id, data._asdict())

def top_stories():
    if os.path.exists("topstories.json"):
        data = json.load(open("topstories.json"))
    else:
        r = session.get("https://hacker-news.firebaseio.com/v0/topstories.json")
        data = r.json()

    return [
        Story(story_id=str(i), title="..", url="", url_domain="..", kids=[], comment_count=0, score=0, initialized=False)._asdict()
        for i in data
    ]


def get_id(_id):
    _id = str(_id)
    r = session.get("https://hacker-news.firebaseio.com/v0/item/" + _id + ".json")
    data = r.json()
    return data


def get_story(_id) -> Story:
    _id = str(_id)
    raw_data = get_id(_id)
    comment_count = raw_data.get("descendants", 0)
    kids = raw_data.get("kids", [])
    score = raw_data["score"]
    title = raw_data["title"]

    if raw_data.get("url"):
        url = raw_data["url"]
        url_domain = raw_data["url"].split("/")[2]
    else:
        url = "self"
        url_domain = "self"

    THREAD_CACHE[_id] = {}
    return Story(
        story_id=_id, title=title, url=url, url_domain=url_domain,
        kids=[{"id": str(k)} for k in kids], comment_count=comment_count,
        score=score, initialized=True,
    )


def bg_fetch_story(story_id):
    thread_q.put(story_id)

def fetch_comment(thread_id, parent_id, _id, depth):
    comment_q.put((str(thread_id), str(parent_id), str(_id), depth))

def get_comment_and_submit(thread_id, parent_id, _id, depth) -> None:
    comment = get_comment(thread_id, parent_id, _id, depth)
    pyotherside.send('comment-pop', comment)


def get_comment(thread_id, parent_id, _id, depth) -> Comment:
    if _id in THREAD_CACHE[thread_id]:
        return THREAD_CACHE[thread_id][_id]

    raw_data = get_id(_id)

    deleted = False
    dead = False
    markup = ""
    user = ""
    if "text" not in raw_data:
        deleted = True
        markup = "deleted"
        user = "deleted"
    else:
        markup = html.unescape(raw_data["text"]).replace('<p>', '<br/><br/>')
        user = raw_data["by"]

    age = _to_relative_time(raw_data['time'])
    dead = raw_data.get("dead", False)
    kids = raw_data.get("kids", [])

    c = Comment(thread_id=str(thread_id), parent_id=str(parent_id), comment_id=str(_id),
                   user=user,
                   markup=markup, kids=[{'id': str(k)} for k in kids],
                   dead=dead, deleted=deleted, age=age,
                   threadVisible=True, initialized=True,
                   depth=depth)._asdict()
    THREAD_CACHE[thread_id][_id] = c
    return c

def purge_queued_comments():
    with comment_q.mutex:
        comment_q.queue.clear()

def _to_relative_time(tstamp):
   now = time.time()
   delta = now - tstamp
   if delta < 0:
       return 'in the future'

   if delta < 60:
       return str(int(delta)) + 's ago'
   delta /= 60
   if delta < 60:
       return str(int(delta)) + 'm ago'
   delta /= 60
   if delta < 24:
       return str(int(delta)) + 'h ago'
   delta /= 24
   if delta < 365:
       return str(int(delta)) + 'd ago'
   delta /= 365
   return str(int(delta)) + 'y ago'
