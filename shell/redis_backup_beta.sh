#!/bin/bash

WORKDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
source $WORKDIR/lib.sh || exit 1
redis_server="$(cmdb_read redis_beta redis_server)"
redis_port=$(cmdb_read redis_beta redis_port)
redis_passwrod="$(cmdb_read redis_beta password)"
backup_path=/app/backup/beta

mkdir -p $backup_path
/usr/local/bin/redis-cli -c -h $redis_server -p $redis_port -a "$redis_passwrod" 'bgsave'

if [ $? -ne 0 ]; then
  echo "ERROR: redis cluster in beta save failed."
  exit 1
fi

cp /app/redis-cluster/$redis_port/data/dump.rdb $backup_path/
if [ ! -f $backup_path/dump.rdb ]; then
  echo "ERROR: remote copy redis dump file from beta failed."
  exit 1
fi

cd $backup_path
tar zcf redis-dump-rdb-$(date '+%Y%m%d%H%M%S').tar.gz dump.rdb
rm -f $backup_path/dump.rdb

find $backup_path -type f -mtime +7 -print -delete

echo "INFO: backup successful completed. file: $backup_path/redis-dump-rdb-$(date '+%Y%m%d%H%M%S').tar.gz"

if [ $? -ne 0 ]; then
  echo "ERROR: redis cluster in beta save failed."
  exit 1
fi
