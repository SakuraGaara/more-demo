#!/bin/bash
#
# Author: Sam <panzhongcai@moneynigeria.com>
# https://docs.aws.amazon.com/zh_cn/AWSEC2/latest/UserGuide/mon-scripts.html
# https://aws.amazon.com/cn/blogs/china/cloudwatch-aws/
#

AWSAccessKeyId="$1"
AWSSecretKey="$2"

if [ -z "$AWSAccessKeyId" -o -z "$AWSSecretKey" ]; then
  echo "Usage: $0 <AWSAccessKeyId> <AWSSecretKey>"
  exit 1
fi

# Install dependency
apt-get update
apt-get install -y unzip libwww-perl libdatetime-perl

# Install cloudwatch
mkdir -p /app/cloudwatch
cd /app/cloudwatch
curl https://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.2.zip -O
unzip CloudWatchMonitoringScripts-1.2.2.zip
rm -f CloudWatchMonitoringScripts-1.2.2.zip
cat << EOF > /app/cloudwatch/aws-scripts-mon/awscreds.conf
AWSAccessKeyId=$AWSAccessKeyId
AWSSecretKey=$AWSSecretKey
EOF

# Run testing
echo "INFO: Run cloudwatch testing..."
/app/cloudwatch/aws-scripts-mon/mon-put-instance-data.pl --mem-util --verify --verbose
if [ $? -ne 0 ]; then
  echo "ERROR: Test failed, please check manually."
  exit 1
else
  echo "INFO: Test successed."
fi

# First commit cloudwatch data
/app/cloudwatch/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/

# Add crontab job
cron_job="*/5 * * * * /app/cloudwatch/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-util --disk-path=/ --from-cron >/dev/null 2>&1 &"
crontab -l | { cat; echo "$cron_job"; } | crontab -

