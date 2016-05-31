#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x
export OPENEDX_RELEASE=$1
APP_VM_COUNT=$2
ADMIN_USER=$3
ADMIN_PASS=$4
ADMIN_HOME=/home/$ADMIN_USER
CONFIG_REPO=https://github.com/edx/configuration.git
ANSIBLE_ROOT=/edx/app/edx_ansible

wget https://raw.githubusercontent.com/edx/configuration/master/util/install/ansible-bootstrap.sh -O- | bash

apt-get -y install sshpass
function send-ssh-key {
    host=$1;user=$2;pass=$3;
    cat /home/$user/.ssh/id_rsa.pub | sshpass -p $pass ssh -o "StrictHostKeyChecking no" $user@$host 'cat >> .ssh/authorized_keys';
}

if [ ! -f $ADMIN_HOME/.ssh/id_rsa ]
then
    ssh-keygen -f $ADMIN_HOME/.ssh/id_rsa -t rsa -N ''
    chown -R $ADMIN_USER:$ADMIN_USER $ADMIN_HOME/.ssh/
fi

for i in `seq 1 $(($APP_VM_COUNT-1))`; do
  echo "10.0.0.1$i" >> inventory.ini
  send-ssh-key 10.0.0.1$i $ADMIN_USER $ADMIN_PASS
done
send-ssh-key 10.0.0.20 $ADMIN_USER $ADMIN_PASS
send-ssh-key 10.0.0.30 $ADMIN_USER $ADMIN_PASS

bash -c "cat <<EOF >extra-vars.yml
---
edx_platform_version: \"$OPENEDX_RELEASE\"
certs_version: \"$OPENEDX_RELEASE\"
forum_version: \"$OPENEDX_RELEASE\"
xqueue_version: \"$OPENEDX_RELEASE\"
configuration_version: \"$OPENEDX_RELEASE\"
edx_ansible_source_repo: \"$CONFIG_REPO\"
EOF"
sudo -u edx-ansible cp *.{ini,yml} $ANSIBLE_ROOT

cd /tmp
git clone $CONFIG_REPO

cd configuration
git checkout $OPENEDX_RELEASE
pip install -r requirements.txt

cd playbooks
#sudo ansible-playbook -i $ANSIBLE_ROOT/inventory.ini -u $ADMIN_USER --private-key=$ADMIN_HOME/.ssh/id_rsa edx-east/mysql.yml -e@$ANSIBLE_ROOT/server-vars.yml -e@$ANSIBLE_ROOT/extra_vars.yml --limit mysql
#sudo ansible-playbook -i $ANSIBLE_ROOT/inventory.ini -u $ADMIN_USER --private-key=$ADMIN_HOME/.ssh/id_rsa edx-east/mongo.yml -e@$ANSIBLE_ROOT/server-vars.yml -e@$ANSIBLE_ROOT/extra_vars.yml --limit mongo --tags "install,manage"
#sudo ansible-playbook -i $ANSIBLE_ROOT/inventory.ini -u $ADMIN_USER --private-key=$ADMIN_HOME/.ssh/id_rsa edx-sandbox.yml -e@$ANSIBLE_ROOT/server-vars.yml -e@$ANSIBLE_ROOT/extra_vars.yml --limit appservers

#sudo ansible-playbook -i $ANSIBLE_ROOT/inventory.ini -u $ADMIN_USER --private-key=$ADMIN_HOME/.ssh/id_rsa $ANSIBLE_ROOT/scalable.yml -e@$ANSIBLE_ROOT/server-vars.yml -e@$ANSIBLE_ROOT/extra_vars.yml
#sudo ansible-playbook -i localhost, -c local edx-east/edxapp_migrate.yml -e@$ANSIBLE_ROOT/server-vars.yml -e@$ANSIBLE_ROOT/extra_vars.yml

# still need memcached config update