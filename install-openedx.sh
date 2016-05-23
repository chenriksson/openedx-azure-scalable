#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x
export OPENEDX_RELEASE=$1
APP_VM_COUNT=$2
ADMIN_USER=$3
ADMIN_PASS=$4

CONFIG_REPO=https://github.com/edx/configuration.git
ANSIBLE_ROOT=/edx/app/edx_ansible

HOMEDIR="/home/$ADMIN_USER"
VMNAME=`hostname`

echo "Deployment test complete"
exit 0

###################################################
# Configure SSH keys
###################################################
time sudo apt-get -y update && sudo apt-get -y upgrade
sudo apt-get -y install sshpass
ssh-keygen -f $HOMEDIR/.ssh/id_rsa -t rsa -N ''

#copy ssh key to all app servers (including localhost)
for i in `seq 0 $(($APP_VM_COUNT-1))`; do
  cat $HOMEDIR/.ssh/id_rsa.pub | sshpass -p $ADMIN_PASS ssh -o "StrictHostKeyChecking no" $ADMIN_USER@10.0.0.1$i 'cat >> .ssh/authorized_keys && echo "Key copied Appserver #$i"'
done
#terrible hack for getting keys onto db server
cat $HOMEDIR/.ssh/id_rsa.pub | sshpass -p $ADMIN_PASS ssh -o "StrictHostKeyChecking no" $ADMIN_USER@10.0.0.20 'cat >> .ssh/authorized_keys && echo "Key copied MySQL"'
cat $HOMEDIR/.ssh/id_rsa.pub | sshpass -p $ADMIN_PASS ssh -o "StrictHostKeyChecking no" $ADMIN_USER@10.0.0.30 'cat >> .ssh/authorized_keys && echo "Key copied MongoDB"'

#make sure premissions are correct
sudo chown -R $ADMIN_USER:$ADMIN_USER $HOMEDIR/.ssh/

###################################################
# Update Ubuntu and install prereqs
###################################################

wget https://raw.githubusercontent.com/edx/configuration/master/util/install/ansible-bootstrap.sh -O- | bash

cat <<EOF >extra-vars.yml
---
edx_platform_version: \"$OPENEDX_RELEASE\"
certs_version: \"$OPENEDX_RELEASE\"
forum_version: \"$OPENEDX_RELEASE\"
xqueue_version: \"$OPENEDX_RELEASE\"
configuration_version: \"$OPENEDX_RELEASE\"
edx_ansible_source_repo: \"$CONFIG_REPO\"
EOF

cat <<EOF >db_vars.yml
---
EDXAPP_MYSQL_USER_HOST: "%"
EDXAPP_MYSQL_HOST: "10.0.0.20"
EDXLOCAL_MYSQL_BIND_IP: "0.0.0.0"
XQUEUE_MYSQL_HOST: "10.0.0.20"
ORA_MYSQL_HOST: "10.0.0.20"
MONGO_BIND_IP: "0.0.0.0"
FORUM_MONGO_HOSTS: ["10.0.0.30"]
EDXAPP_MONGO_HOSTS: ["10.0.0.30"]
EDXAPP_MEMCACHE: ["10.0.0.20:11211"]
MEMCACHED_BIND_IP: "0.0.0.0"
EOF

sudo -u edx-ansible cp *.yml $ANSIBLE_ROOT

#create inventory.ini file
cat <<EOF >inventory.ini
[mongo-server]
10.0.0.30

[mysql-server]
10.0.0.20

[edxapp-primary-server]
localhost

[edxapp-additional-server]
EOF
for i in `seq 1 $(($APP_VM_COUNT-1))`; do
  echo "10.0.0.1$i" >> inventory.ini
done

cd /tmp
time git clone $CONFIG_REPO

cd configuration
git checkout $OPENEDX_RELEASE
pip install -r requirements.txt
cd playbooks


sudo ansible-playbook -i inventory.ini -u $ADMIN_USER --private-key=$HOMEDIR/.ssh/id_rsa multiserver_deploy.yml -e@/tmp/server-vars.yml -e@/tmp/extra_vars.yml -e@/tmp/db_vars.yml