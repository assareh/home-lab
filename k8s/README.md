# K8s Stuff

## Consul Installation Steps
I am installing Consul on K3s as `dc2`, and federating with the `dc1` Consul cluster running on VMs.

1. Create the federation secret on your target kubernetes cluster: (this requires your Consul CA cert and key and gossip encryption key)
```
kubectl create secret generic consul-federation \
--from-literal="caCert=$(cat pki_int_consul_ca_cert.pem)" \
--from-literal="caKey=$(cat pki_int_consul_ca_key.pem)" \
--from-literal="gossipEncryptionKey=`pbpaste`"
```

2. Create the enterprise license secret:
```
kubectl create secret generic consul-license --from-literal="key="`pbpaste`""
```

3. Install Consul:
```
helm install -f values-consul.yaml consul hashicorp/consul
```

### Links and References
- https://www.consul.io/docs/k8s/installation/multi-cluster/vms-and-kubernetes#kubernetes-as-the-secondary

## Vault Installation Steps
I am installing the Vault Sidecar Injector configured to retrieve secrets from an external Vault cluster (the Vault cluster running on VMs).

1. Create a secret with the CA certificate so Vault agents can verify Vault servers without producing certificate warnings: 
```
kubectl create secret generic tls-test-client --from-file=ca.pem=./ca.pem
```

2. Install Vault:
```
helm install -f values-vault.yaml vault hashicorp/vault
```

3. We need to gather the values necessary for configuring the `kubernetes` auth method in Vault. 
```
VAULT_HELM_SECRET_NAME=$(kubectl get secrets --output=json | jq -r '.items[].metadata | select(.name|startswith("vault-token-")).name')
TOKEN_REVIEW_JWT=$(kubectl get secret $VAULT_HELM_SECRET_NAME --output='go-template={{ .data.token }}' | base64 --decode)
KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')
```

Save the value of `TOKEN_REVIEW_JWT`, `KUBE_CA_CERT`, and `KUBE_HOST`. We'll use these to configure the `kubernetes` auth method in Vault. The configuration can be found in the [vault](../vault) folder.

### Links and References
- https://learn.hashicorp.com/tutorials/vault/kubernetes-external-vault#install-the-vault-helm-chart