#/bin/bash
# please pass in the system name prefix as an argument like so:
# ./bootstrap.sh castle

# get machine IP address
IP=$(ifconfig ens160 | grep -E -o "(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-4]|2[0-4][0-9]|[01]?[0-9][0-9]?)" | head -n 1)

# this section is for castle only
if [ $1 == castle ]
then

# edit vault config
echo "--> Updating Vault config"
sed -i 's/ADDRESS/'"$IP"'/g' /home/ubuntu/vault.hcl

# install vault certificate and kms creds
echo "--> Installing Vault cert and KMS creds"
vault agent -config vault-agent-bootstrap.hcl
sudo mv tls.* /opt/vault/tls/.
sudo mkdir -p /usr/vault
sudo mv vault-kms.json /usr/vault/.
sudo chown -R vault:vault /usr/vault
sudo chmod -R 400 /usr/vault/vault-kms.json
fi

# this section is for moat only
if [ $1 == moat ]
then

# install nginx certificate
echo "--> Installing nginx cert"
sed -i 's/ADDRESS/'"$IP"'/g' /home/ubuntu/cert.tpl
sed -i 's/ADDRESS/'"$IP"'/g' /home/ubuntu/key.tpl
vault agent -config vault-agent-bootstrap.hcl
sudo mv tls.crt /etc/ssl/certs/.
sudo mv tls.key /etc/ssl/private/.
fi
