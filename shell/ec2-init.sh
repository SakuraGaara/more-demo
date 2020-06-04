#!/bin/bash
#
# Initialize AWS EC2 Ubuntu Server
# Version: 0.1.0
# Author: Sam <panzhongcai@moneynigeria.com>
#

HOSTNAME="$1"

VERSION=0.1.0
NOW=$(date '+%Y%m%d%H%M%S')
LIB=/app/shell/lib.sh

if [ ! -f $LIB ]; then
  echo "ERROR: $LIB not found."
  exit 1
fi
. $LIB

ec2_init_version=$(cmdb_read ec2_init version)
if [ -n "$ec2_init_version" ]; then
  print_error "Server has been initialized."
fi
cmdb_write ec2_init version "$VERSION"

# Add users
add_user 1801 admin
add_user 1802 log
chmod 755 /home/admin /home/log

# Add ssh-keys

mkdir -p /root/.ssh
chmod 600 /root/.ssh
if [ -f /root/.ssh/authorized_keys ]; then
  sed -i '/ sam@seattle/d; / root@ie-1/d' /root/.ssh/authorized_keys
fi
cat << EOF >> /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFLnBok0evUxsOLiK3vwVTCJ3BEjptvIG7jE716ARhJi8YG+MyvG/MrVTXNXRlSX0qr75YVr1FHnHzcCM4TzcTWL4JQpTUChQ/vG1cUE+NvsBmIJAyOHNI7pJEAvjLFeCD3hSpBgIjfwYcflFJtQMxyuMWmJxDha92hmrvLluUPt5Vmc+lw8FeldavswJmchudVWJkVL4HEbuy0kSsDzEQSsq1E3hyx0/S91N3VCHp1vuU3UW+S2g8hop+FzjFOFZTvFhnnBmTQDlmz1UopWsKwC8DWG7zOj3L8UaFe+RqBmnXx7CPh8RBh4G+4qlpa3Hxj0b2cAX9MxjUdi6PCjCD sam@seattle
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQChp2uaaZ0O3ZzGpxCgQr4Np4jirhOXS+bdztKzrree9VLTYhMaFdAf/Tuf/1fJDRGUxCugkTSgw48hxz7qdQT90oc4+dlGRkPEOJEyt3b19Swf2TK/TeN4RI4/W2pCd4errqpR4cL/EmIhh5wN5AJ3D4tBIVYpv6/kk07xAblkvTrHl8dUt/hF57J3uFLohu3H7Z3JuoZ4TcI4k88mHdECZOGunHUbXdlbWenR331Zm3Oi/XUsEn1UpitvAvT07H/PzSzBkyR53Eb/iZJf0FtoVL+LDI3pwpPQpg8Czj9SboKLMCrSMGddBZGc3tb9biYEnj3qCXQIXY2zZSKeFo5J root@ie-1
EOF
chmod 600 /root/.ssh/authorized_keys

# Set hostname
if [ -n "$HOSTNAME" ]; then
  hostname $HOSTNAME
  echo "$HOSTNAME" > /etc/hostname
  sed -i "s/^\(127.0.0.1.*\)$/\1 $HOSTNAME/g" /etc/hosts
fi

# Config profiles
cat << 'EOF' >> /etc/profile

umask 077

export PS1="\n[ \[\e[0;35m\]\u\[\e[0m\]@\[\e[0;31m\]\`hostname\`\[\e[0m\]:\[\e[0;33m\]\`pwd\`\[\e[0m\] \[\e[0;32m\]\`date '+%Y-%m-%d %H:%M:%S %a'\`\[\e[0m\] ]\n\\\$ "

export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

export EDITOR=/usr/bin/vim

export HISTFILESIZE=1000000
export HISTSIZE=1000000
export HISTTIMEFORMAT="[%Y-%m-%d %H:%M:%S] "

alias vi=vim
alias ls='ls --color=auto'
alias ll='ls --color=auto -l'
alias l='ls --color=auto -lA'
alias grep='grep --color'
alias auto-update='apt autoremove -y && apt clean all && apt -o Acquire::Check-Valid-Until=false update && apt upgrade -y && apt dist-upgrade -y'

export PATH="$PATH:/app/shell"

EOF
cat << 'EOF' >> /etc/skel/.profile

. /etc/profile >/dev/null 2>&1
EOF

cat << 'EOF' >> /root/.profile

. /etc/profile >/dev/null 2>&1
EOF

# Add swapfile

if [ ! -f /swapfile ]; then
  total_disk=$(df -m | awk '/\/$/ {print $2}')
  if [ $total_disk -gt 40000 ]; then
    dd if=/dev/zero of=/swapfile count=4096 bs=1MiB
  else
    dd if=/dev/zero of=/swapfile count=2048 bs=1MiB
  fi
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  cat << 'EOF' >>/etc/fstab
/swapfile               swap                    swap    defaults        0 0
EOF
fi

# Modify system limits

mkdir -p /app/backup
cp /etc/security/limits.d/20-nproc.conf /app/backup/20-nproc.conf.$NOW

cat << 'EOF' > /etc/security/limits.d/20-nproc.conf
*       soft    nofile  65535
*       hard    nofile  65535
root    soft    nofile  65535
root    hard    nofile  65535

*       soft    core    unlimited
*       hard    core    unlimited
root    soft    core    unlimited
root    hard    core    unlimited

*       soft    nproc   unlimited
*       hard    nproc   unlimited
root    soft    nproc   unlimited
root    hard    nproc   unlimited
EOF

# Modify sysctl.conf

netdev=$(ip route | awk '/^default /{print $NF}')
mv /etc/sysctl.conf /app/backup/sysctl.conf.$NOW
cat << EOF > /etc/sysctl.conf
fs.file-max=2097152
fs.nr_open=2097152

net.core.netdev_max_backlog=16384
net.core.optmem_max=16777216
net.core.rmem_default=262144
net.core.rmem_max=16777216
net.core.somaxconn=65535
net.core.wmem_default=262144
net.core.wmem_max=16777216

net.ipv4.conf.all.arp_announce=2
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.${netdev}.rp_filter = 0
net.ipv4.conf.lo.arp_announce=2

net.ipv4.ip_forward=1
net.ipv4.ip_local_port_range=1024 65535

net.ipv4.neigh.default.base_reachable_time_ms = 600000
net.ipv4.neigh.default.gc_stale_time=120
net.ipv4.neigh.default.mcast_solicit = 20
net.ipv4.neigh.default.retrans_time_ms = 250

net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_syn_backlog=16384
net.ipv4.tcp_max_tw_buckets=1048576
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_mem=16777216 16777216 16777216
net.ipv4.tcp_rmem=1024 4096 16777216
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamps = 0
#net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 0
net.ipv4.tcp_wmem=1024 4096 16777216

net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0

vm.max_map_count = 262144
vm.swappiness = 10
EOF
sysctl -p

# yum install -y locale
apt-get update
apt-get install -y locale
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
apt-get install -y locales
locale-gen

apt-get install -y iftop htop curl wget vim tmux
