TODO
- Need to implement a static mesh gateway address one way or another

1. Create the federation secret:
```
kubectl create secret generic consul-federation \
    --from-literal=caCert=$(cat consul-agent-ca.pem) \
    --from-literal=caKey=$(cat consul-agent-ca-key.pem) \
    --from-literal=gossipEncryptionKey="<your gossip encryption key>"
    # If ACLs are enabled uncomment.
    # --from-literal=replicationToken="<your acl replication token>"
```

2. Create the license secret:
```
kubectl create secret generic consul-license --from-literal="key=$(<YOUR LICENSE FROM CSM>)"
```

3. Double check the `primary_gateways` addresses in [Consul-values.yaml](./Consul-values.yaml).

4. Install Consul:
```
helm install -f Consul-values.yaml consul hashicorp/consul
```

## Links and References
- https://www.consul.io/docs/k8s/installation/multi-cluster/vms-and-kubernetes#kubernetes-as-the-secondary