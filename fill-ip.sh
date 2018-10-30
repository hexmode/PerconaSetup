#!/bin/bash
for server in $SERVER_LIST; do
    echo $server $(ssh $server /sbin/ip -o -4 a | awk '!/ lo / {print $4}' | sed s,/.*,,)
done
