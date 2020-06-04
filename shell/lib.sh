#!/usr/bin/env bash
#
# Author: Sam <panzhongcai@moneynigeria.com>
#

# 终端文本颜色定义
export black='\033[0m'
export boldblack='\033[1;0m'
export red='\033[31m'
export boldred='\033[1;31m'
export green='\033[32m'
export boldgreen='\033[1;32m'
export yellow='\033[33m'
export boldyellow='\033[1;33m'
export blue='\033[34m'
export boldblue='\033[1;34m'
export magenta='\033[35m'
export boldmagenta='\033[1;35m'
export cyan='\033[36m'
export boldcyan='\033[1;36m'
export white='\033[37m'
export boldwhite='\033[1;37m'
export reset='\033[0m'

# 打印INFO日志
print_info() {
  echo "INFO: $*"
}

# 打印NOTICE日志
print_notice(){
  echo -e "${green}NOTICE: $* ${reset}"
}

# 打印WARNING日志
print_warning() {
  echo -e "${yellow}WARNING: $* ${reset}"
}

# 打印ERROR日志
print_error() {
  echo -e "${red}ERROR: $* ${reset}"
}

# 本机IP
get_ip_addr() {
  ip route get 1 | sed 's/^.*src \([^ ]*\).*$/\1/g' | head -1
}

# 从cmdb 中获取配置
cmdb_read() {
  local workdir="/app/cmdb"
  local table="$1"
  local key="$2"
  local file=${workdir}/${table}.conf
  if [ -f "$file" ]; then
    cat $file | grep -E "^${key}[ ]*=.*$" | tail -1 | sed "s/^${key}[ ]*=[ ]*\(.*\)[ ]*$/\1/g"
  fi
}

# 将配置写入cmdb
cmdb_write() {
  local workdir="/app/cmdb"
  local table="$1"
  local key="$2"
  local value="$3"
  local file=${workdir}/${table}.conf
  if [ -f "$file" ]; then
    sed -i "/^${key}=/d" $file
  fi
  mkdir -p $workdir
  echo "$key=$value" >> $file
}

# 指定id添加用户
add_user() {
  local user_id="$1"
  local user_name="$2"

  id -u $user_name &>/dev/null
  if [ $? -eq 0 ]; then
    print_error "User $user_name exists."
    exit 1
  fi

  grep -E "^${user_name}:" /etc/group &>/dev/null
  if [ $? -eq 0 ]; then
    print_error "Group $user_name exists."
    exit 1
  fi

  groupadd -g $user_id $user_name
  useradd -u $user_id -g $user_name -G $user_name -s /bin/bash -m $user_name
}

total_memory() {
  free -m | awk '/Mem/ {print $2}'
}

free_memory() {
  free -m | awk '/Mem/ {print $NF}'
}

total_fs_space() {
  local fs=$(echo "$1" | sed 's#/#\/#g')
  df -m | awk "/$fs/ {print \$2}"
}
