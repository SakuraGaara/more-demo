#!/bin/bash
#
# Author: Sam <panzhongcai@moneynigeria.com>
#

if [ -z "$1" -o -z "$2" ]; then
    echo "Usage: $0 <local_path> <remote_path>"
    exit 1
fi

if [ ! -f $HOME/.ssh/config ]; then
    echo "ERROR: config file not found."
    exit 1
fi

server_list=$(cat $HOME/.ssh/config | awk '/^Host /{print $NF}' | grep -v code.nigeriainternal.com)

for server in ${server_list[@]}; do
    scp -r "$1" $server:"$2"
done
