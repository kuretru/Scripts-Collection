#!/usr/bin/env python3
# coding=utf-8

"""
ZJUT DrCom Python Client
Version: 1.0
Required: Python 3.5(+)
Author: Eugene Wu <kuretru@gmail.com>
URL: https://github.com/kuretru/Scripts-Collection
"""

import argparse
import json
import os
import socket
import sys
from urllib import parse, request

SESSION_ID = '0squo4034j8e86jd5g7vj69490'
UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.88 Safari/537.36'


def dormitory(username: str, password: str, ip: str, mode: str):
    proto = '@localpfyx' if mode == 'dormitory' else '@cmccpfyx'
    params = {
        'c': 'ACSetting', 'a': 'Login', 'protocol': 'http:', 'hostname': '192.168.210.111',
        'iTermType': '1', 'mac': '000000000000',
        'ip': ip,
        'enAdvert': '0', 'loginMethod': '1'
    }
    headers = {
        'Cookie': 'program=gdpf; vlan=0; PHPSESSID=%s; ip=%s; areaID=wlanuserip %s' % (SESSION_ID, ip, ip),
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': UA
    }
    body = {
        'DDDDD': ',0,' + username + proto,
        'upass': password,
        'R1': '0', 'R2': '0', 'R6': '0', 'para': '00', '0MKKey': '123456',
        'buttonClicked': '', 'redirect_url': '', 'err_flag': '', 'username': '',
        'password': '', 'user': '', 'cmd': '', 'login': ''
    }

    url = 'http://192.168.210.111:801/eportal/?' + parse.urlencode(params)
    data = parse.urlencode(body).encode('utf-8')
    req = request.Request(url, data=data, headers=headers, method='POST')
    send_request(req)


def wlan(username: str, password: str, ip: str):
    params = {
        'c': 'Portal', 'a': 'login', 'callback': 'dr1003', 'login_method': '1',
        'user_account': ',0,' + username,
        'user_password': password,
        'wlan_user_ip': ip,
        'wlan_user_ipv6': '', 'wlan_user_mac': '000000000000',
        'wlan_ac_ip': '', 'wlan_ac_name': '', 'jsVersion': '3.3.3',
        'v': '1234'
    }
    headers = {
        'Cookie': 'PHPSESSID=%s' % SESSION_ID,
        'User-Agent': UA
    }

    url = 'http://192.168.8.1:801/eportal/?' + parse.urlencode(params)
    req = request.Request(url, headers=headers, method='GET')
    send_request(req)


def laboratory(username: str, password: str, ip: str):
    params = {
        'c': 'Portal', 'a': 'login', 'callback': 'dr1003', 'login_method': '1',
        'user_account': ',0,' + username,
        'user_password': password,
        'wlan_user_ip': ip,
        'wlan_user_ipv6': '', 'wlan_user_mac': '000000000000',
        'wlan_ac_ip': '192.168.6.36', 'wlan_ac_name': 'ME60', 'jsVersion': '3.3.3',
        'v': '1234'
    }
    headers = {
        'Cookie': 'PHPSESSID=%s' % SESSION_ID,
        'User-Agent': UA
    }

    url = 'http://192.168.6.1:801/eportal/?' + parse.urlencode(params)
    req = request.Request(url, headers=headers, method='GET')
    send_request(req)


def send_request(req):
    response = request.urlopen(req)
    html = response.read().decode('gb2312')
    success = False
    left = html.find('<title>')
    right = html.find('</title>')
    if left != -1 and right != -1:
        success = True
        title = html[left + 7:right]
        print(title)
    elif html.find('dr1003(') != -1:
        success = True
        left = html.find('{')
        right = html.find('}')
        text = html[left:right + 1]
        result = json.loads(text)
        print(result)
        print('\n')
    if not success:
        print('发送请求失败')



def get_ip_address(ifname: str):
    if ifname is None or ifname == '':
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('172.16.7.10', 53))
        return s.getsockname()[0]
    else:
        return os.popen('ip addr show ' + ifname).read().split('inet ')[1].split('/')[0]


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='浙江工业大学Dr.Com客户端 v1.0')
    parser.add_argument('--mode', help='模式，寝室楼连实验室(dormitory, 默认)，寝室楼连移动(cmcc)，无线Wi-Fi(wlan)，实验室(laboratory)', default='dormitory')
    parser.add_argument('--interface', help='网络接口，(e.g. wan, eth0, ens33)')
    parser.add_argument('--username', help='用户名', required=True)
    parser.add_argument('--password', help='密码', required=True)
    args = parser.parse_args()

    ip = get_ip_address(args.interface)
    if args.mode == 'dormitory' or args.mode == 'cmcc':
        dormitory(args.username, args.password, ip, args.mode)
    elif args.mode == 'wlan':
        wlan(args.username, args.password, ip)
    elif args.mode == 'laboratory':
        laboratory(args.username, args.password, ip)
    else:
        print('unknown mode')
        sys.exit(2)
