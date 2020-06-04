#!/bin/bash
#
# Auto update static assets.
# Author: Sam <panzhongcai@moneynigeria.com>
#

. /etc/profile >/dev/null 2>&1

cd /app/html/kepay-h5

git pull
