#!/bin/bash

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
sudo apt-get install curl -y

# Install net-tools for ifconfig command
sudo apt-get install net-tools -y 

# Install K3s server (master node)
curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode 644 --flannel-iface=eth1

# Wait for K3s to be ready
while ! kubectl get node 2>/dev/null; do
    sleep 1
done

# Get node token for worker nodes
cat /var/lib/rancher/k3s/server/node-token > $NODE_TOKEN_FILE