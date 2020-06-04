#!/bin/bash

pid=$(pidof prometheus | xargs)
if [ -z "$pid" ]; then
    echo "ERROR: process id not found."
    exit 1
else
    if [ `whoami` == 'prometheus' ]; then
        kill -HUP $pid
    else
        su - prometheus -c "kill -HUP $pid"
    fi
    echo "INFO: finished."
  fi
