#!/bin/bash
#
# Goofy的Docker部署脚本
# 参数1：cmdb_read goofy server_environment
# 参数2：image id
# Author: Sam <panzhongcai@moneynigeria.com>
#

WORKDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
source $WORKDIR/lib.sh

server_log_path=/home/kepay/goofy/logs
contrainer_log_path=/home/kepay/goofy/logs

spring_profiles_active=$(cmdb_read goofy server_environment)
if [ -z "$spring_profiles_active" ]; then
  print_error "Value of spring_profiles_active is null."
  exit 1
fi

if [ -z "$1" ]; then
  print_info "Usage: $0 <id>"
  exit 1
fi

java_opts=$(cmdb_read goofy java_opts)
if [ -z "$java_opts" ]; then
  print_warning "JAVA_OPTS is null."
fi

upgrade_id="$1"
if [ ${#upgrade_id} -ne 7 ]; then
  print_error "Image id length != 7"
  exit 1
fi

current_id=$(docker ps --filter name=goofy | grep registry.docker.nigeriainternal.com | awk '{print $2}' | awk -F '-' '{print $NF}')

if [ "$upgrade_id" == "$current_id" -a "--force" != "$2" ]; then
  print_error "Image id is already running, use --force to deploy."
  exit 1
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] current_id=$current_id upgrade_id=$upgrade_id" >> /app/logs/deploy.log
print_info "Environment: spring_profiles_active = $spring_profiles_active"

docker pull registry.docker.nigeriainternal.com/kepay/goofy:1.0.0-SNAPSHOT-$upgrade_id
if [ $? -ne 0 ]; then
  print_error "Pull image 'registry.docker.nigeriainternal.com/kepay/goofy:1.0.0-SNAPSHOT-$upgrade_id' failed."
  exit 1
fi

ip_addr=$(get_ip_addr)
if [ -z "$ip_addr" ]; then
  print_warning "Use 127.0.0.1 to listen ports."
  ip_addr="127.0.0.1"
fi
contrainer_ids=$(docker ps --filter name=goofy -q)
if [ -n "$contrainer_ids" ]; then
  print_info "Stop container ..."
  docker stop $contrainer_ids
fi

contrainer_ids=$(docker ps --filter name=goofy -aq)
if [ -n "$contrainer_ids" ]; then
  docker rm -f $contrainer_ids
fi

docker run -d \
  --name goofy \
  --restart=always \
  -p $ip_addr:8191:8191 \
  -p $ip_addr:20001:20001 \
  -e "APOLLO_META=http://apollo-meta.kepayonline.com:8080" \
  -v $server_log_path:$contrainer_log_path \
  -e "SPRING_PROFILES_ACTIVE=$spring_profiles_active" \
  -e "JAVA_OPTS=$java_opts" \
  registry.docker.nigeriainternal.com/kepay/goofy:1.0.0-SNAPSHOT-$upgrade_id

