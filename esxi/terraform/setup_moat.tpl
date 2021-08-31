#!/bin/bash
# Script to set up and start core services

# run bootstrap script for consul config
touch /home/ubuntu/secret_id
echo ${secret_id} >> /home/ubuntu/secret_id
cd /home/ubuntu && ./bootstrap.sh moat

# start consul
sudo mv /home/ubuntu/consul.hcl /etc/consul.d/.
sudo chown consul:consul /etc/consul.d/consul.hcl
sudo systemctl enable consul
sudo systemctl start consul

# start consul-template
sudo systemctl enable consul-template
sudo systemctl start consul-template

# start other interfaces
sudo mv /home/ubuntu/01-netcfg.yaml /etc/netplan/01-netcfg.yaml
sudo netplan apply