import time
import json
import os
import queue

import requests

from typing import List, NamedTuple
from concurrent.futures import ThreadPoolExecutor

import pyotherside

session = requests.Session()

BG_TASKS = ThreadPoolExecutor(max_workers=3)

Comment = NamedTuple(
    "Comment",
    [
        ("parent_id", int),
        ("comment_id", int),
        ("user", str),
        ("markup", str),
        ("kids", List[int]),
        ("dead", bool),
        ("deleted", bool),
        ("age", str),
    ],
)
Story = NamedTuple(
    "Story",
    [
        ("story_id", int),
        ("title", str),
        ("url", str),
        ("url_domain", str),
        ("kids", List[int]),
        ("comment_count", int),
        ("score", int),
    ],
)


def fetch_and_signal(_id):
    data = get_story(_id)
    time.sleep(0.01)
    pyotherside.send("thread-pop", _id, data._asdict())


def top_stories():
    if os.path.exists("topstories.json"):
        data = json.load(open("topstories.json"))
    else:
        r = session.get("https://hacker-news.firebaseio.com/v0/topstories.json")
        #with open("topstories.json", "w") as fd:
        #    fd.write(r.text)
        data = r.json()

    for _id in data:
        BG_TASKS.submit(fetch_and_signal, _id)
    return [
        Story(story_id=i, title="", url="", url_domain="?", kids='', comment_count=0, score=0)._asdict()
        for i in data[:50]
    ]


def get_id(_id):
    _id = str(_id)
    if os.path.exists(_id + ".json"):
        return json.load(open(_id + ".json"))
    r = session.get("https://hacker-news.firebaseio.com/v0/item/" + _id + ".json")
    #open(_id + ".json", "w").write(r.text)
    data = r.json()
    return data


def get_story(_id) -> Story:
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

    return Story(
        story_id=_id, title=title, url=url, url_domain=url_domain, kids=[str(k) for k in kids], comment_count=comment_count, score=score
    )


def _to_relative_time(tstamp):
    now = time.time()
    delta = now - tstamp
    if delta < 0:
        return 'in the future'

    if delta < 60:
        return str(delta) + 's ago'
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


def get_comment(parent_id, _id) -> Comment:
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
        # FIXME
        markup = raw_data["text"]
        user = raw_data["by"]

    age = _to_relative_time(raw_data['time'])
    dead = raw_data.get("dead", False)
    kids = raw_data.get("kids", [])

    return Comment(parent_id=str(parent_id), comment_id=str(_id), user=user, markup=markup, kids=[str(k) for k in kids], dead=dead, deleted=deleted, age=age)._asdict()
