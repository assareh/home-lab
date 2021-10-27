#!/bin/sh -eu

KUBE_VERSION=v1.21.5

echo "==> Installing kubectl $KUBE_VERSION"
cd /tmp
curl -LO "https://storage.googleapis.com/kubernetes-release/release/${KUBE_VERSION}/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl
kubectl version --client

HELM_VERSION=v3.4.0

echo "==> Installing helm $HELM_VERSION"
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
DESIRED_VERSION=$HELM_VERSION ./get_helm.sh
helm version