#!/bin/bash
getWsrep() {
    arg=$1

    WSREP=$(echo "show status like 'wsrep_$arg';" |
                mysql -u root -p"$NEWPW" 2>&1 |
                awk "/^wsrep_$arg/ {print \$2}")
    echo $WSREP
}
ready=$(getWsrep ready)
if [ "$ready" != "ON" ]; then
    echo "Not ready."
    exit 1
fi

connected=$(getWsrep connected)
if [ "$connected" != "ON" ]; then
    echo "Not connected."
    exit 1
fi

local_state_uuid=$(getWsrep local_state_uuid)
if [ -z "$local_state_uuid" ]; then
    echo "Could not find the local_state_uuid."
    exit 1
fi

local_state_comment=$(getWsrep local_state_comment)
if [ "$local_state_comment" != "Synced" ]; then
    echo "Local state is not synced."
    exit 1
fi

echo "Looks like everything is in place"
