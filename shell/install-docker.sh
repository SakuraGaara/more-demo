#!/bin/bash
#
# Author: Sam <panzhongcai@moneynigeria.com>
#

apt-get remove -y docker docker-engine docker.io

apt-get update

apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update

mkdir -p /etc/docker /app/docker
cat << 'EOF' > /etc/docker/daemon.json
{
    "data-root": "/app/docker/docker"
}
EOF

apt-get install -y docker-ce

echo "
=====================================
You need to login to docker registry:
$ sudo docker login -u kepayadmin registry.docker.nigeriainternal.com"

