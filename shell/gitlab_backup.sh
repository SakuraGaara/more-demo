#!/bin/bash

. /etc/profile

SSH_OPTS="-q -o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o CheckHostIP=no -o LogLevel=quiet -i ~/.ssh/id_rsa"
SSH_HOST=18.210.58.1
SSH_USER=root
SSH_PORT=22
BAK_PATH=/var/opt/gitlab/backups
LOCAL_PATH=/app/backup/gitlab

FILENAME=$(ssh $SSH_OPTS -p $SSH_PORT $SSH_USER@$SSH_HOST "cd $BAK_PATH && ls -1rt *.tar | tail -1")
mkdir -p $LOCAL_PATH
if [ -f $LOCAL_PATH/$FILENAME ]; then
    echo "ERROR: File exists."
    exit 1
fi
scp $SSH_OPTS -P $SSH_PORT $SSH_USER@$SSH_HOST:$BAK_PATH/$FILENAME $LOCAL_PATH/
echo "INFO: Finished."

find $LOCAL_PATH -type f -name "*.tar" -mtime +3 -print -delete
