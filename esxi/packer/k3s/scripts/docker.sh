#!/bin/bash -eu

echo "==> Updating list of repositories"
apt-get clean
apt-get -y update

echo "==> Installing base package"
apt-get install -y git vim gpm

echo "==> Installing docker"
apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get -y update
apt-get -y install docker-ce
usermod -aG docker ${SSH_USERNAME}

echo "==> Adding docker to systemd"
mv /home/${SSH_USERNAME}/docker.service /lib/systemd/system/docker.service
chmod 644 /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart docker