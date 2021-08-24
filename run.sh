#!/bin/sh
set -e
ip=192.168.2.154
ip=192.168.2.156
clickable build   --ssh $ip
clickable install --ssh $ip
clickable launch  --ssh $ip
clickable logs    --ssh $ip
