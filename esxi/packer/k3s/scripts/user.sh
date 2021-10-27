#!/bin/sh -eu

HOMEDIR=${HOME:-/home/$SSH_USERNAME}

# install kubectl completion
echo 'source <(kubectl completion bash)' >> /home/${SSH_USERNAME}/.bashrc
kubectl completion bash >/etc/bash_completion.d/kubectl
echo 'alias k=kubectl' >> /home/${SSH_USERNAME}/.bashrc
echo 'complete -F __start_kubectl k' >> /home/${SSH_USERNAME}/.bashrc

# make sur the home directory of the user is owned by the user
chown -R ${SSH_USERNAME}:${SSH_USERNAME} /home/${SSH_USERNAME}