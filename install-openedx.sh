#!/bin/bash
# Copyright (c) Microsoft Corporation. All Rights Reserved.
# Licensed under the MIT license. See LICENSE file on the project webpage for details.

set -x
export OPENEDX_RELEASE=$1
APP_VM_COUNT=$2
ADMIN_USER=$3
ADMIN_PASS=$4
CONFIG_REPO=https://github.com/chenriksson/configuration.2.git
CONFIG_VERSION=dogwood.3.1
ANSIBLE_ROOT=/edx/app/edx_ansible

wget https://raw.githubusercontent.com/edx/configuration/master/util/install/ansible-bootstrap.sh -O- | bash

apt-get -y install sshpass
function send-ssh-key {
    host=$1;user=$2;pass=$3;
    cat /home/$user/.ssh/id_rsa.pub | sshpass -p $pass ssh -o "StrictHostKeyChecking no" $user@$host 'cat >> .ssh/authorized_keys';
}

if [ ! -f ~$ADMIN_USER/.ssh/id_rsa ]
then
    ssh-keygen -f ~$ADMIN_USER/.ssh/id_rsa -t rsa -N ''
    chown -R $ADMIN_USER:$ADMIN_USER ~$ADMIN_USER/.ssh/
fi

for i in `seq 0 $(($APP_VM_COUNT-1))`; do
  send-ssh-key 10.0.0.1$i $ADMIN_USER $ADMIN_PASS
done
send-ssh-key 10.0.0.20 $ADMIN_USER $ADMIN_PASS
send-ssh-key 10.0.0.30 $ADMIN_USER $ADMIN_PASS

for i in `seq 1 $(($APP_VM_COUNT-1))`; do
  echo "10.0.0.1$i" >> inventory.ini
done

bash -c "cat <<EOF >extra-vars.yml
---
edx_platform_version: \"$OPENEDX_RELEASE\"
certs_version: \"$OPENEDX_RELEASE\"
forum_version: \"$OPENEDX_RELEASE\"
xqueue_version: \"$OPENEDX_RELEASE\"
configuration_version: \"$CONFIG_VERSION\"
edx_ansible_source_repo: \"$CONFIG_REPO\"
COMMON_SSH_PASSWORD_AUTH: \"yes\"
EOF"
sudo -u edx-ansible cp *.{ini,yml} $ANSIBLE_ROOT

cd /tmp
git clone $CONFIG_REPO configuration

cd configuration
git checkout $CONFIG_VERSION
pip install -r requirements.txt

cd playbooks
export ANSIBLE_OPT_VARS="-e@$ANSIBLE_ROOT/server-vars.yml -e@$ANSIBLE_ROOT/extra-vars.yml"
export ANSIBLE_OPT_SSH="-u $ADMIN_USER --private-key=~$ADMIN_USER/.ssh/id_rsa"
sudo ansible-playbook edx_mongo.yml -i "10.0.0.30," $ANSIBLE_OPT_SSH $ANSIBLE_OPT_VARS
sudo ansible-playbook edx_mysql.yml -i "10.0.0.20," $ANSIBLE_OPT_SSH $ANSIBLE_OPT_VARS
sudo ansible-playbook edx_sandbox.yml -i "localhost," -c local $ANSIBLE_OPT_VARS -e "migrate_db=yes"
sudo ansible-playbook edx_sandbox.yml -i $ANSIBLE_ROOT/inventory.ini $ANSIBLE_OPT_SSH $ANSIBLE_OPT_VARS --limit app
