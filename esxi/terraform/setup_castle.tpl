#!/bin/bash
# Script to set up and start core services

# run bootstrap script for vault configs and vault certs
touch /home/ubuntu/secret_id
echo ${secret_id} >> /home/ubuntu/secret_id
cd /home/ubuntu && ./bootstrap.sh castle

# start consul
sudo systemctl enable consul
sudo systemctl start consul
sleep 10

# start vault
sudo mv /home/ubuntu/vault.hcl /etc/vault.d/vault.hcl
sudo chown vault:vault /etc/vault.d/vault.hcl
sudo chmod 640 /etc/vault.d/vault.hcl
sudo systemctl enable vault
sudo systemctl start vault
sleep 10

# start nomad
sudo systemctl enable nomad
sudo systemctl start nomad

# run the tfc-agent for angryhippo org
# nomad job run /home/ubuntu/tfc-agent.hcl