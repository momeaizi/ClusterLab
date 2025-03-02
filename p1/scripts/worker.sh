#!/bin/bash

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
sudo apt-get install -y curl


# Wait for the node token to be available
while [ ! -f /vagrant/node-token ]; do
    sleep 1
done

# Install K3s agent (worker node)
# Setting the K3S_URL parameter causes the installer to configure K3s as an agent, instead of a server. 
# The K3s agent will register with the K3s server listening at the supplied URL . 
curl -sfL https://get.k3s.io | K3S_URL="https://${MASTER_IP}:6443" K3S_TOKEN=$(cat /vagrant/node-token) sh -s -  --flannel-iface=eth1