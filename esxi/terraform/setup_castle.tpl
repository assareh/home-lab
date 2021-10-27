# Get Vault token and start Consul, Vault, Nomad

# Capture and redirect
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/home/${ssh_username}/setup_castle.log 2>&1

# Everything below will go to the file 'setup_castle.log':

# print executed commands
set -x

# get machine IP address and name
IP=$(ifconfig ens160 | grep -E -o "(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)" | head -n 1)
HOST=`hostname`

# write IP address into vault config
sed -i 's/ADDRESS/'"$IP"'/g' /home/${ssh_username}/vault.hcl

# write IP address into templates before calling vault agent
sed -i 's/ADDRESS/'"$IP"'/g' /home/${ssh_username}/consul-server-cert.tpl
sed -i 's/ADDRESS/'"$IP"'/g' /home/${ssh_username}/consul-server-key.tpl

# write hostname into templates before calling vault agent
sed -i 's/HOSTNAME/'"$HOST"'/g' /home/${ssh_username}/consul-server-cert.tpl
sed -i 's/HOSTNAME/'"$HOST"'/g' /home/${ssh_username}/consul-server-key.tpl

# write IP address into templates before calling vault agent
sed -i 's/ADDRESS/'"$IP"'/g' /home/${ssh_username}/consul-client-cert.tpl
sed -i 's/ADDRESS/'"$IP"'/g' /home/${ssh_username}/consul-client-key.tpl

# write hostname into templates before calling vault agent
sed -i 's/HOSTNAME/'"$HOST"'/g' /home/${ssh_username}/consul-client-cert.tpl
sed -i 's/HOSTNAME/'"$HOST"'/g' /home/${ssh_username}/consul-client-key.tpl

# auth to vault
cd /home/${ssh_username} && vault agent -config vault-agent-bootstrap.hcl

# install vault certificates and kms creds
sudo mv tls.* /opt/vault/tls/.
sudo mkdir -p /usr/vault
sudo mv vault-kms-264205-019d22c9f50c.json /usr/vault/.
sudo chown -R vault:vault /usr/vault
sudo chmod -R 400 /usr/vault/vault-kms-264205-019d22c9f50c.json
sudo mv /home/${ssh_username}/dc1-client-consul.pem /etc/vault.d/.
sudo mv /home/${ssh_username}/dc1-client-consul-key.pem /etc/vault.d/.

# save token for nomad
mv vault-token-via-agent /home/${ssh_username}/nomad.env
sed -i '1s/^/VAULT_TOKEN=/' /home/${ssh_username}/nomad.env
sudo mv /home/${ssh_username}/nomad.env /etc/nomad.d/nomad.env
sudo chown -R nomad:nomad /etc/nomad.d

# install consul server cert and key
sudo mv /home/${ssh_username}/dc1-server-consul.pem /etc/consul.d/.
sudo mv /home/${ssh_username}/dc1-server-consul-key.pem /etc/consul.d/.
sudo chown consul:consul /etc/consul.d/dc1-server-consul.pem /etc/consul.d/dc1-server-consul-key.pem
sudo chmod 640 /etc/consul.d/dc1-server-consul.pem
sudo chmod 400 /etc/consul.d/dc1-server-consul-key.pem

# start consul
sudo systemctl enable consul
sudo systemctl start consul
sleep 10

# start vault
sudo mv /home/${ssh_username}/vault.hcl /etc/vault.d/vault.hcl
sudo chown vault:vault /etc/vault.d/*
sudo chmod 640 /etc/vault.d/*
sudo chmod 400 /etc/vault.d/dc1-client-consul-key.pem
sudo systemctl enable vault
sudo systemctl start vault
sleep 10

# start nomad
sudo systemctl enable nomad
sudo systemctl start nomad