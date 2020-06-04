#!/bin/bash

IP_ADDR=$(ip route get 1 | sed 's/^.*src \([^ ]*\).*$/\1/g' | head -1)

install_binary() {
    local BASE_DIR=/app/prometheus/node_exporter
    local VERSION="0.16.0"
    if [ -d $BASE_DIR ]; then
        echo "ERROR: prometheus is already installed."
        exit 1
    fi
    mkdir -p $BASE_DIR
    cd $BASE_DIR
    wget -q https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-amd64.tar.gz
    tar xf node_exporter-${VERSION}.linux-amd64.tar.gz
    mv $BASE_DIR/node_exporter-${VERSION}.linux-amd64/node_exporter $BASE_DIR/
    rm -rf $BASE_DIR/node_exporter-${VERSION}.linux-amd64*
}

install_for_systemctl() {
    cat << EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=node_exporter
After=network.target
[Service]
Type=simple
User=root
ExecStart=/app/prometheus/node_exporter/node_exporter \
    --web.listen-address=${IP_ADDR}:9100 \
    --collector.netstat.fields=(.*) \
    --collector.vmstat.fields=(.*) \
    --collector.interrupts
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl restart node_exporter
    systemctl status node_exporter
}

install_for_initd() {
   cat << EOF > /etc/init.d/node_exporter
#!/bin/sh
# chkconfig: 2345 99 20

. /etc/rc.d/init.d/functions
node_exporter_bin=/app/prometheus/node_exporter/node_exporter

start() {
    ps aux | grep -v grep | grep -q $node_exporter_bin
    if [ $? -eq 0 ]; then
        action "node_exporter is running"
    else
        nohup $node_exporter_bin --web.listen-address=${IP_ADDR}:9100 >> /var/log/node_exporter.log 2>&1 &
        if [ $? -eq 0 ]; then
            action "Starting node_exporter: " /bin/true
        else
            action "Starting node_exporter: " /bin/false
        fi
    fi
}

stop() {
    pid=$(ps aux | grep -v grep | grep $node_exporter_bin | awk '{print $2}')
    if [ -z "$pid" ]; then
        action "node_exporter is stopped"
    else
        kill -9 $pid
        if [ $? -eq 0 ]; then
            action "Stopping node_exporter: " /bin/true
        else
            action "Stopping node_exporter: " /bin/false
        fi
    fi
}

status() {
    ps aux | grep -v grep | grep -q $node_exporter_bin
    if [ $? -eq 0  ];then
        action "node_exporter is running"
    else
        action "node_exporter is stopped"
    fi
}

restart() {
    stop
    sleep 1
    start
}

main() {
    case "$1" in
        start)
            start
        ;;
        stop)
            stop
        ;;
        status)
            status
            ;;
        restart)
            restart
            ;;
        *)
            echo "Usage: $0 <start|stop|status|restart>"
    esac
}

main $*
EOF

   chmod +x /etc/init.d/node_exporter
   chkconfig --add node_exporter
   service node_exporter start
   chkconfig node_exporter on
}

main() {
    install_binary
    command -v systemctl >/dev/null
    if [ $? -eq 0 ]; then
        install_for_systemctl
    else
        install_for_initd
    fi
}

main $*
