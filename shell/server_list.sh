#!/bin/bash
#
# Author: Sam <panzhongcai@moneynigeria.com>
#

if [ -f $HOME/.ssh/config ]; then
  cat $HOME/.ssh/config | \
    awk '/^Host /{print $NF}' | \
    grep -v code.nigeriainternal.com
fi
