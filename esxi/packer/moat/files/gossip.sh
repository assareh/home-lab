#!/bin/bash -e
sudo sed -i -E "s/encrypt[ \t]+= \"/encrypt = \"$consul_gossip/" /etc/consul.d/consul.hcl