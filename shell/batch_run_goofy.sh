#!/bin/bash
#
# Author: Sam <panzhongcai@moneynigeria.com>
#

if [ -z "$1" ]; then
    echo "Usage: $0 <command>"
    exit 1
fi

if [ ! -f $HOME/.ssh/config ]; then
    echo "ERROR: config file not found."
    exit 1
fi

server_list=$(cat $HOME/.ssh/config | awk '/^Host /{print $NF}' | grep goofy)

for server in ${server_list[@]}; do
    ssh $server "$1"
done
