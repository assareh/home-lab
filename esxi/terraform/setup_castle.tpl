# Get Vault token and start Consul, Vault, Nomad

# Capture and redirect
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/home/${ssh_username}/setup_castle.log 2>&1

# Everything below will go to the file 'setup_castle.log':

# print executed commands
set -x

# get machine IP address
IP=$(ifconfig ens160 | grep -E -o "(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)" | head -n 1)

# write IP address into vault config 
sed -i 's/ADDRESS/'"$IP"'/g' /home/${ssh_username}/vault.hcl

# auth to vault
cd /home/${ssh_username} && vault agent -config vault-agent-bootstrap.hcl

# install vault certificate and kms creds
sudo mv tls.* /opt/vault/tls/.
sudo mkdir -p /usr/vault
sudo mv vault-kms-264205-019d22c9f50c.json /usr/vault/.
sudo chown -R vault:vault /usr/vault
sudo chmod -R 400 /usr/vault/vault-kms-264205-019d22c9f50c.json

# save token for nomad
mv vault-token-via-agent /home/${ssh_username}/nomad.env
sed -i '1s/^/VAULT_TOKEN=/' /home/${ssh_username}/nomad.env
sudo mv /home/${ssh_username}/nomad.env /etc/nomad.d/nomad.env
sudo chown -R nomad:nomad /etc/nomad.d

# start consul
sudo systemctl enable consul
sudo systemctl start consul
sleep 10

# start vault
sudo mv /home/${ssh_username}/vault.hcl /etc/vault.d/vault.hcl
sudo chown vault:vault /etc/vault.d/vault.hcl
sudo chmod 640 /etc/vault.d/vault.hcl
sudo systemctl enable vault
sudo systemctl start vault
sleep 10

# start nomad
sudo systemctl enable nomad
sudo systemctl start nomad