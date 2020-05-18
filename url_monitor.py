#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import time
import urllib.parse
import urllib.request

# Server酱通信密钥
SCKEY = ""

# 要检测变更的页面列表
URLS = [
    "http://www.baidu.com/"
]

# 检测页面变更间隔(单位:秒)
INTERVAL = 30

SERVER_CHAN_URL = "https://sc.ftqq.com/"
SERVER_CHAN_title = "检测到页面变更"

database = {}


def now():
    return time.strftime("%Y-%m-%d %H:%M:%S    ", time.localtime())


def request(url):
    response = urllib.request.urlopen(urllib.parse.quote(url, safe="/:?=&"))
    return response.read().decode("UTF-8")


def server_chan_notice(text):
    url = "{}{}.send?text={}&desp={}".format(SERVER_CHAN_URL, SCKEY, SERVER_CHAN_title, text)
    data = json.loads(request(url))
    if data["errno"] == 0:
        print("{}Server酱通知成功".format(now()))
    else:
        print("{}Server酱通知失败：{}".format(now(), data["errmsg"]))


def check_changes():
    changed_list = []
    for url in URLS:
        response = request(url)
        length = len(response)
        if url in database and database[url] != length:
            changed_list.append(url)
        database[url] = length
    if len(changed_list) > 0:
        print("{}发现{}个网页发生变更".format(now(), len(changed_list)))
        text = ""
        for changed in changed_list:
            text = text + changed + "\n"
        server_chan_notice(text)
    else:
        print("{}没有发现变更".format(now(), len(changed_list)))


if __name__ == '__main__':
    while True:
        check_changes()
        time.sleep(INTERVAL)
