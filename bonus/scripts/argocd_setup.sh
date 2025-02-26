#!/bin/bash

# Define colors
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'

CONFIG="./confs/kubeconfig.yml"

# Function to print section headers with a box style
print_header() {
  local message="$1"
  local length=${#message}
  local border=$(printf '─%.0s' $(seq 1 $((length + 8))))

  echo -e "${MAGENTA}┌${border}┐${RESET}"
  echo -e "${MAGENTA}│    ${CYAN}${message}${MAGENTA}    │${RESET}"
  echo -e "${MAGENTA}└${border}┘${RESET}"
}

# Function to handle errors
handle_error() {
  echo -e "${RED}✖ ERROR: $1${RESET}"
  exit 1
}

# Function to print status messages
status_msg() {
  echo -e "${GREEN}✔ $1${RESET}"
}

# Create required Kubernetes namespaces
print_header "Setting Up Kubernetes Namespaces"
for ns in dev argocd; do
  if kubectl --kubeconfig $CONFIG get namespace "$ns" &> /dev/null; then
    status_msg "Namespace '$ns' already exists."
  else
    kubectl --kubeconfig $CONFIG create namespace "$ns" || handle_error "Failed to create namespace '$ns'."
    status_msg "Namespace '$ns' created successfully."
  fi
done

# Install ArgoCD
print_header "Deploying ArgoCD (GitOps for Kubernetes)"
kubectl --kubeconfig $CONFIG apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || handle_error "ArgoCD deployment failed."
kubectl --kubeconfig $CONFIG wait --for=condition=Ready pods --all -n argocd --timeout=300s || handle_error "ArgoCD pods did not become ready."
status_msg "ArgoCD has been successfully deployed."

# Expose ArgoCD Server
print_header "Exposing ArgoCD UI on Port 8088"
if curl -s -o /dev/null localhost:8088; then
  status_msg "ArgoCD is already accessible at http://localhost:8088"
else
  kubectl --kubeconfig $CONFIG port-forward svc/argocd-server --address 0.0.0.0 8088:80 -n argocd & 
  status_msg "ArgoCD UI is now accessible at http://localhost:8088"
fi

# Display ArgoCD login credentials
print_header "ArgoCD Access Credentials"
echo -e "${GREEN}URL:      http://localhost:8088${RESET}"
echo -e "${GREEN}Username: admin${RESET}"
echo -e "${GREEN}Password: $(kubectl --kubeconfig $CONFIG get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode)${RESET}"

# Deploy application using ArgoCD
print_header "Configuring ArgoCD to Sync with Repository"
kubectl --kubeconfig $CONFIG apply -f ./confs/applications/application.yaml -n argocd || handle_error "Failed to apply application.yaml."
status_msg "ArgoCD is now monitoring the repository for changes."

# Wait for application pods to be ready
print_header "Waiting for Application Pods to Start"
kubectl --kubeconfig $CONFIG wait --for=condition=Ready pods --all -n dev --timeout=300s || handle_error "Application pods did not become ready."
status_msg "All application pods are running."

print_header "Setup Complete! ArgoCD and Kubernetes Namespaces are Ready."
