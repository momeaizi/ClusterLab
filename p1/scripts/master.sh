#!/bin/bash

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
sudo apt-get install curl -y

# Set DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

# Install K3s server (master node)
curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode 644 --flannel-iface=eth1

# Wait for K3s to be ready
while ! kubectl get node 2>/dev/null; do
    sleep 1
done

# Get node token for worker nodes
cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token

# Configure kubectl for vagrant user
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc