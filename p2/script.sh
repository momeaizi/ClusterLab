#!/bin/bash

# Ensure curl is installed
if ! command -v curl &> /dev/null; then
  sudo apt install curl -y
fi

# Uninstall existing k3s if present
if command -v k3s &> /dev/null; then
  sudo /usr/local/bin/k3s-uninstall.sh
fi

# Install and start k3s
if ! command -v k3s &> /dev/null; then
  sudo curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode=644 --node-ip 127.0.0.1 --bind-address=127.0.0.1" sh -s -
  
  # Start k3s server manually
  sudo nohup /usr/local/bin/k3s server --write-kubeconfig-mode=644 --node-ip 127.0.0.1 --bind-address=127.0.0.1 > /var/log/k3s.log 2>&1 &
  
  # Wait for API server to start
  export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
  until kubectl get nodes >/dev/null 2>&1; do
    echo "Waiting for k3s API server to start..."
    sleep 5
  done
  kubectl get nodes
fi

echo "******** DEPLOYMENT ********"
cd deployment
kubectl apply -f . --validate=false

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pods --all --timeout=300s

echo "******** SERVICES ********"
cd ../services
kubectl apply -f . --validate=false

# Wait for services to be created
echo "Waiting for services to be ready..."
kubectl wait --for=jsonpath='{.spec.selector.app}' -f ./ --timeout=300s

echo "******** INGRESS ********"
cd ../ingress
kubectl apply -f . --validate=false

echo "******** END ********"