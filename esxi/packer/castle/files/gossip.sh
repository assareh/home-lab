#!/bin/bash -e
sudo sed -i -E "s/encrypt[ \t]+= \"/encrypt = \"$consul_gossip/" /etc/consul.d/consul.hcl
sudo sed -i -E "s/encrypt[ \t]+= \"/encrypt          = \"$nomad_gossip/" /etc/nomad.d/nomad.hcl