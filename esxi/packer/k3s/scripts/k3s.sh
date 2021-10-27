#!/bin/sh -eu

HOMEDIR=${HOME:-/home/$SSH_USERNAME}
# K3S_VERSION=${K3S_VERSION:-v1.17.14+k3s2}

# https://rancher.com/docs/k3s/latest/en/installation/install-options/
# export INSTALL_K3S_VERSION=${K3S_VERSION}
export INSTALL_K3S_EXEC="--disable=traefik"

echo "==> Creating cluster (k3s-version: $K3S_VERSION)"
curl -sfL https://get.k3s.io | sh -
k3s ctr version

echo "==> Setup kube configuration"
mkdir -p $HOMEDIR/.kube
cp /etc/rancher/k3s/k3s.yaml $HOMEDIR/.kube/config