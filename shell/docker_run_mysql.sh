#!/bin/bash
#
# Author: Sam <panzhongcai@moneynigeria.com>
#

storage_conf=/app/docker/mysql/5.7/conf
storage_data=/app/docker/mysql/5.7/data
mkdir -p $storage_conf
mkdir -p $storage_data

cat << 'EOF' > /app/docker/mysql/5.7/conf/my.cnf
[client]
port                           = 3306
socket                         = /var/run/mysqld/mysqld.sock

[mysqld_safe]
socket                         = /var/run/mysqld/mysqld.sock
nice                           = 0

[mysqld]
skip-host-cache
skip-name-resolve
skip-external-locking
user                           = mysql
pid-file                       = /var/run/mysqld/mysqld.pid
socket                         = /var/run/mysqld/mysqld.sock
bind-address                   = 0.0.0.0
port                           = 3306
basedir                        = /usr
datadir                        = /var/lib/mysql
tmpdir                         = /tmp
default-storage-engine         = InnoDB

key_buffer_size                = 64M
max_allowed_packet             = 64M
thread_stack                   = 192K
thread_cache_size              = 8

myisam-recover-options         = FORCE,BACKUP
max_connections                = 2000

query_cache_limit              = 1M
query_cache_size               = 32M

innodb_file_format             = Barracuda
innodb_buffer_pool_size        = 1G
innodb_data_file_path          = ibdata1:200M:autoextend
innodb_file_per_table          = 1
innodb_flush_log_at_trx_commit = 1
innodb_flush_method            = O_DIRECT
innodb_log_files_in_group      = 2
innodb_log_file_size           = 512M
innodb_status_file             = 1
innodb_strict_mode             = 0
innodb_large_prefix

#general_log_file              = /var/lib/mysql/mysql-general.log
#general_log                   = 1

log_error                      = /var/lib/mysql/mysql-error.log

slow_query_log_file            = /var/lib/mysql/mysql-slow.log
slow_query_log                 = 1
long_query_time                = 2
log_queries_not_using_indexes  = 1

#server-id                     = 1
#log_bin                       = /var/lib/mysql/mysql-bin.log
#expire_logs_days              = 14
#max_binlog_size               = 100M
#sync-binlog                   = 1

#chroot                        = /var/lib/mysql/

[mysqldump]
quick
quote-names
max_allowed_packet             = 64M

[mysql]
port                           = 3306
socket                         = /var/run/mysqld/mysqld.sock
prompt                         = "\\u@\\d \\r:\\m:\\s > "
EOF

password=$(openssl rand -base64 12)

docker run -d \
    --name mysql \
    -e "MYSQL_ROOT_PASSWORD=$password" \
    -v "$stroage_conf:/etc/mysql/conf.d" \
    -v "$storage_data:/var/lib/mysql" \
    -p 3306:3306 \
    --restart=always \
    mysql:5.6

