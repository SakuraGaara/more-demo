#!/bin/bash

AWS_ACCESS_KEY_ID="$1"
AWS_SECRET_ACCESS_KEY="$2"
AWS_REGION="$3"

if [ -z "$AWS_ACCESS_KEY_ID" -o -z "$AWS_SECRET_ACCESS_KEY" -o -z "$AWS_REGION" ]; then
  echo "Usage: $0 <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY> <AWS_REGION>"
  exit 1
fi

docker run -d \
  --name sqs-exporter \
  --restart=always \
  -p 9384:9384 \
  -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
  -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
  -e AWS_REGION=${AWS_REGION} \
  jmal98/sqs-exporter:0.0.5

docker logs sqs-exporter

ipAddr=$(ip route get 1 | sed 's/^.*src \([^ ]*\).*$/\1/g' | head -1)
echo "INFO: curl -v http://${ipAddr}:9384/metrics"

