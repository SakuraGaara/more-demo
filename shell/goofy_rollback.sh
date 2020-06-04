#!/bin/bash
#
# Docker deploy rollback
# Author: Sam <panzhongcai@moneynigeria.com>
#

spring_profiles_active=ireland
server_log_path=/home/kepay/goofy/logs
contrainer_log_path=/home/kepay/goofy/logs

last_id=$(tail -1 /home/kepay/goofy/logs/deploy.log | sed 's/^.*upgrade_id=\(.*\)$/\1/g')

if [ -z "$last_id" ]; then
    echo "ERROR: last id error."
    exit 1
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] last_id=$last_id" >> /app/logs/rollback.log

ip_addr=$(ifconfig | awk '/inet addr:172.31/{print substr($2,6)}')

contrainer_ids=$(docker ps --filter name=goofy -q)
if [ -n "$contrainer_ids" ]; then
    docker stop $contrainer_ids
    docker rm -f $contrainer_ids
fi

docker run -d \
    --name goofy \
    --restart=always \
    -p $ip_addr:8191:8191 \
    -p $ip_addr:20001:20001 \
    -v $server_log_path:$contrainer_log_path \
    -e "SPRING_PROFILES_ACTIVE=$spring_profiles_active" \
    registry.docker.nigeriainternal.com/kepay/goofy:1.0.0-SNAPSHOT-$last_id
