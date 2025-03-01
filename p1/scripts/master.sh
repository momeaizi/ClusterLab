#!/bin/bash

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y curl net-tools

# Install K3s server (master node)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--bind-address=${MASTER_IP} --node-external-ip=${MASTER_IP}" sh -

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