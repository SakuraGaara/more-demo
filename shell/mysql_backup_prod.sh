#!/bin/bash

. /etc/profile
umask 077

backup_path=/app/backup/prod
mysql_host=kepay-goofy-prod-cluster.cluster-cfuhouvypgaj.eu-west-1.rds.amazonaws.com

backup() {
  local schema="$1"
  local backup_file=${schema}_$(date '+%Y%m%d%H%M%S').sql
  local compress_file=${schema}_$(date '+%Y%m%d%H%M%S').tar.gz

  mkdir -p $backup_path
  cd $backup_path
  mysqldump \
      --quick=true \
      --max_allowed_packet=256M \
      --single-transaction \
      -h$mysql_host \
      $schema > $backup_file
  
  if [ $? -ne 0 ]; then
      echo "ERROR: backup $schema to $backup_file failed."
      exit 1
  fi
  
  tar zcf $compress_file $backup_file
  rm -f $backup_file

  find $backup_path -type f -mtime +7 -print -delete

  echo "INFO: ($schema) backup successful completed. file: $backup_path/$compress_file"
}

main() {
  backup epaydb
}

main $*
