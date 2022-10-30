#!/bin/bash
#==================================================
# OS Passed:    CentOS7
# Description:  服务器登录时自动发送登录提醒
# Author:       kuretru < kuretru@gmail.com >
# Github:       https://github.com/kuretru/Scripts-Collection
# Version:      1.2.190921
#==================================================

#Server酱调用密钥
KEY='Your SCKEY'

USER=$(whoami)
HOSTNAME=$(hostname)
IP=$(strings /var/log/lastlog | grep -o -P "(\d+\.)(\d+\.)(\d+\.)\d+")
NOW=$(date "+%Y-%m-%d_%H:%M:%S")

wget -q --spider https://sc.ftqq.com/${KEY}.send?text="${HOSTNAME}登录提醒"\&desp="时间${NOW}，用户名${USER}，IP地址${IP}"
