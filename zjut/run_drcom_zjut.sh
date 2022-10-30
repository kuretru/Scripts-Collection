#!/bin/sh

# ZJUT DrCom Python Client Runner
# Version: 1.1
# Required: Python 3.5(+)
# Author: Eugene Wu <kuretru@gmail.com>
# URL: https://github.com/kuretru/Scripts-Collection

PROG=/root/drcom_zjut.py
MODE=dormitory
INTERFACE=br-edu
USERNAME=211*******
PASSWORD=********

result=$(/usr/bin/python3 $PROG --mode $MODE --interface $INTERFACE --username $USERNAME --password $PASSWORD)
logger -t KT-DEBUG "Run DrCom Python Client: $result"
