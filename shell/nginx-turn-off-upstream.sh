#!/bin/bash
#
# a/b 发布时，关闭参数所在机房的流量
# turn off a -> deploy a -> turn off b -> deploy b -> recover
# 参数1：目标配置后缀名: a | b | recover
#
# Author: Sam <panzhongcai@moneynigeria.com>
#

set -e

WORKDIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
source $WORKDIR/lib.sh
CONF_PATH=/app/openresty/nginx/conf
NGX_BIN=/app/openresty/bin/openresty

print_help() {
    print_info "Usage: $0 <a|b|recover>" && exit 1
}

switch_config() {
    local target="$1"
    local configs=( $CONF_PATH/server-http/kepay-api.upstream \
                    $CONF_PATH/server-tcp/kepay-nova.upstream \
                    $CONF_PATH/server-http/kepay-admin.upstream)
    print_notice "Turning off upstream, all requests will be forwarded to [$target] servers."
    for config in ${configs[@]}; do
        rm -f ${config}
        cp ${config}.${target} ${config}
    done
    $NGX_BIN -t &>/dev/null
    $NGX_BIN -s reload
    print_notice "Finished, please check nginx logs in /app/logs/nginx"
}

main() {
    case "$1" in
                a) target="b" ;;
                b) target="a" ;;
        r|recover) target="all" ;;
                *) print_help ;;
    esac
    switch_config "$target"
}

main $*
