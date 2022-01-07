#!/bin/sh

# ZJUT Network detector
# Version: 1.1
# Required: Python 3.5(+)
# Author: Eugene Wu <kuretru@gmail.com>
# URL: https://github.com/kuretru/Scripts-Collection

PROG=/root/run_drcom_zjut.sh
INTERFACE=enp14s0
PING_HOST=223.5.5.5

result=$(ping -I $INTERFACE -c 4 $PING_HOST | grep ttl | wc -l)

if [ $result -gt 0 ]
then
    exit 0
fi

echo "Network not connect, login......"
sh $PROG
