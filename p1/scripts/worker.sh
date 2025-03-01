#!/bin/bash

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y curl openssh-server

# Wait for the node token to be available
while [ ! -f /vagrant/node-token ]; do
    sleep 1
done

# Install K3s agent (worker node)
# Setting the K3S_URL parameter causes the installer to configure K3s as an agent, instead of a server. 
# The K3s agent will register with the K3s server listening at the supplied URL . 
curl -sfL https://get.k3s.io | K3S_URL="https://${MASTER_IP}:6443" K3S_TOKEN=$(cat /vagrant/node-token) sh -