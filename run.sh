#!/bin/sh
set -e
ip=192.168.2.155
clickable build   --ssh $ip
clickable install --ssh $ip
clickable launch  --ssh $ip
clickable logs    --ssh $ip
