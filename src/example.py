import time
import json
import os
import queue
import html
import threading
import sys

import requests

from urllib.parse import urlparse, parse_qs
from pathlib import Path
from typing import List, NamedTuple, Dict
from html.parser import HTMLParser

here = os.path.abspath(os.path.dirname(__file__))
vendored = os.path.join(here, 'vendored')
sys.path.insert(0, vendored)

from bs4 import BeautifulSoup

import pyotherside

session = requests.Session()
thread_q = queue.Queue()

NUM_BG_THREADS = 6
SEARCH_URL = 'https://hn.algolia.com/api/v1/search'
ITEMS_URL = 'https://hn.algolia.com/api/v1/items/'
TOP_STORIES_URL = 'https://hacker-news.firebaseio.com/v0/topstories.json'

CONFIG_PATH = Path('/home/phablet/.config/hnr.davidv.dev/')
CONFIG_FILE = CONFIG_PATH / 'config.json'
CONFIG = {}
if not CONFIG_PATH.exists():
    CONFIG_PATH.mkdir()

if not CONFIG_FILE.exists():
    with CONFIG_FILE.open('w') as fd:
        json.dump({'cookie': None}, fd)

with CONFIG_FILE.open() as fd:
    try:
        CONFIG = json.load(fd)
    except Exception as e:
        CONFIG = {'cookie': None}

def save_config():
    cfg = json.dumps(CONFIG, indent=4)
    with CONFIG_FILE.open('w') as fd:
        fd.write(cfg)
    get_settings()

Comment = NamedTuple(
    "Comment",
    [
        ("thread_id", str),
        ("parent_id", str),
        ("comment_id", str),
        ("user", str),
        ("markup", str),
        ("kids", List[Dict[str, str]]),
        ("dead", bool),
        ("deleted", bool),
        ("age", str),
        ("depth", int),
        ("threadVisible", bool),
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
        ("highlight", int),
        ("user", str),
        ("age", str),
    ],
)

def do_work():
    while True:
        t = thread_q.get()
        fetch_and_signal(t)

for i in range(NUM_BG_THREADS):
    t = threading.Thread(target=do_work)
    t.daemon = True
    t.start()

def fetch_and_signal(_id):
    pyotherside.send("thread-pop", get_story_stub(_id))

def top_stories():
    r = requests.get(TOP_STORIES_URL)
    data = r.json()
    return [
        Story(story_id=str(i), title="..", url="", url_domain="..", kids=[], comment_count=0, score=0,
              initialized=False, highlight=0, user="", age="")._asdict()
        for i in data
    ]

def get_story_stub(_id):
    data = get_id(_id)
    s = Story(story_id=str(_id),
                 title=data['title'],
                 url=data.get('url', 'self'),
                 url_domain=get_domain(data.get('url', '//self')),
                 kids=[],
                 comment_count=data.get('descendants', 0),
                 score=data['score'],
                 initialized=True,
                 highlight=0,
                 user=data['by'],
                 age=_to_relative_time(data['time']))._asdict()
    return s

def get_id(_id):
    _id = str(_id)
    r = session.get("https://hacker-news.firebaseio.com/v0/item/" + _id + ".json")
    data = r.json()
    return data

def get_domain(url):
    return url.split("/")[2]

def flatten(children, depth):
    res = []
    for c in children:
        _k = c.pop('children')
        c['depth'] = depth
        c['hasKids'] = any(True for k in _k if k['text'] or k['children'])
        res.append(c)
        res.extend(flatten(_k, depth + 1))
    return res

def get_story(_id) -> Dict:
    _id = str(_id)

    t = time.time()
    reply = requests.get(ITEMS_URL + _id)
    if not reply.ok:
        pyotherside.send("fail", reply.status_code)
        return None

    raw_data = reply.json()
    print('Fetching story took', time.time() - t, flush=True)
    if raw_data['type'] == 'comment':
        # app is opening a link directly to a comment
        story_id = requests.get(ITEMS_URL + _id).json()['story_id']
        story = get_story(story_id)
        print('Fetched a comment..', _id)
        story['highlight'] = int(_id)
        return story
    else:
        score = raw_data["points"]
        title = raw_data["title"]

    kids = raw_data.get("children", [])

    if raw_data.get("url"):
        url = raw_data["url"]
        url_domain = get_domain(raw_data["url"])
    else:
        url = "self"
        url_domain = "self"

    kids = flatten(kids, 0)

    if raw_data["text"]:  # self-story
        _self = raw_data.copy()
        _self.pop('children')
        kids.insert(0, _self)

    now = time.time()
    kids = [{'threadVisible': True,
             'age': _to_relative_time(k['created_at_i']),
             'markup': k['text'] or '',
             'comment_id': k['id'],
             'created_days_ago': (now - k['created_at_i']) // 86400,
             **k}
             for k in kids if k['text'] or k['hasKids']]
    story = Story(
        story_id=_id, title=title, url=url, url_domain=url_domain,
        kids=kids, comment_count=len(kids),
        score=score, initialized=True, highlight='',
        user=raw_data["author"],
        age=_to_relative_time(raw_data['created_at_i']),
        )
    return story._asdict()


def bg_fetch_story(story_id):
    thread_q.put(story_id)

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

def search(query, tags='story'):
    r = requests.get(SEARCH_URL, params={'query': query, 'tags': tags, 'hitsPerPage': 50})
    r.raise_for_status()
    data = r.json()['hits']

    return [
        Story(story_id=str(i['objectID']),
              title=i['title'],
              url=i['url'],
              url_domain=get_domain(i['url'] or '//self'),
              kids=[],
              comment_count=i['num_comments'],
              score=i['points'],
              initialized=False,
              highlight=0,
              user=i['author'],
              age=_to_relative_time(i['created_at_i']),
              )._asdict()
        for i in data
    ]

def html_to_plaintext(h):
    class HTMLFilter(HTMLParser):
        text = ""
        parsing_anchor = False

        def handle_starttag(self, tag, attrs):
            if tag == 'p':
                self.text += '\n'
            elif tag == 'a':
                self.text += dict(attrs)['href']
                self.parsing_anchor = True
        def handle_endtag(self, tag):
            if tag == 'a':
                self.parsing_anchor = False
        def handle_data(self, data):
            if not self.parsing_anchor:
                self.text += data

    f = HTMLFilter()
    f.feed(h)
    return f.text

def login_and_store_cookie(user, password):

    LOGIN_URL = 'https://news.ycombinator.com/login'
    session = requests.Session()

    payload = { 'acct': user, 'pw': password }
    r = session.post(LOGIN_URL, data=payload)
    cookies = session.cookies.get_dict()
    if 'user' in cookies:
        CONFIG['cookie'] = cookies['user']
        save_config()
        return True
    return False

def get_settings():
    pyotherside.send('settings', CONFIG)


def get_auth_for_id(_id):
    cookies = {'user': CONFIG['cookie']}
    url = 'https://news.ycombinator.com/item?id=' + _id
    r = requests.get(url, cookies=cookies)
    soup = BeautifulSoup(r.text, 'html.parser')
    for a in soup.find_all('a'):
        if not a.get('href'):
            continue
        href = a['href']
        u = urlparse(href)
        qp = parse_qs(u.query)
        if 'auth' not in qp or qp.get('id') != [_id]:
            continue
        return qp['auth'][0]

def get_hmac_for_id(_id):
    cookies = {'user': CONFIG['cookie']}
    url = 'https://news.ycombinator.com/item?id=' + _id
    r = requests.get(url, cookies=cookies)
    soup = BeautifulSoup(r.text, 'html.parser')
    _input = soup.find('input', {'name': 'hmac'})
    if _input:
        return _input.get('value')


def vote_up(comment_id):
    auth = get_auth_for_id(comment_id)
    if not auth:
        print('Failed to get auth', flush=True)
        return
    VOTE_URL = 'https://news.ycombinator.com/vote'
    cookies = {'user': CONFIG['cookie']}

    r = requests.get(VOTE_URL, params={'id': comment_id, 'how': 'up', 'auth': auth}, cookies=cookies)


def send_reply(comment_id, text):
    hmac = get_hmac_for_id(comment_id)
    if not hmac:
        return False, "Could not fetch authentication code"

    COMMENT_URL = 'https://news.ycombinator.com/comment'
    payload = {'parent': comment_id,
               'hmac': hmac,
               'text': text,
               'goto': 'item?id=' + comment_id,
               }
    print('Submitting', payload)
    cookies = {'user': CONFIG['cookie']}

    headers = {"Content-Type": "application/x-www-form-urlencoded" }
    r = requests.post(COMMENT_URL, data=payload, headers=headers, cookies=cookies)
    if not r.ok:
        return False, "Failed to submit: " + r.status_code
    return True, ""
