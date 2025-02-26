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

# Create required namespaces
print_header "Setting Up Kubernetes Namespaces"
for ns in dev argocd; do
  if kubectl --kubeconfig $CONFIG get namespace "$ns" &> /dev/null; then
    status_msg "Namespace '$ns' already exists."
  else
    kubectl --kubeconfig $CONFIG create namespace "$ns" || handle_error "Failed to create namespace '$ns'."
    status_msg "Namespace '$ns' created successfully."
  fi
done

# Install or upgrade GitLab using Helm
print_header "Installing or Upgrading GitLab"
helm repo add gitlab http://charts.gitlab.io/
helm upgrade --install my-gitlab gitlab/gitlab --create-namespace --namespace gitlab \
  --kubeconfig $CONFIG \
  -f ./confs/values.yaml \
  --timeout 800s || handle_error "Failed to install or upgrade GitLab"

# Wait until the webservice is ready
print_header "Waiting for GitLab Webservice to be Ready"
kubectl --kubeconfig $CONFIG wait --for=condition=ready --timeout=1800s pod -l app=webservice -n gitlab || handle_error "GitLab webservice did not become ready in time"

# Retrieve the initial root password for GitLab
print_header "Retrieving GitLab Initial Root Password"
export GITLAB_PASSWORD=$(kubectl --kubeconfig $CONFIG get secret my-gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode) || handle_error "Failed to retrieve GitLab initial root password"
echo -e "${GREEN}GITLAB PASSWORD: $GITLAB_PASSWORD${RESET}"

# Port-forward to access GitLab
print_header "Setting Up Port Forwarding to Access GitLab"
if pgrep -f "kubectl port-forward svc/my-gitlab-webservice-default" > /dev/null; then
  status_msg "Port forwarding is already set up"
else
  kubectl --kubeconfig $CONFIG port-forward svc/my-gitlab-webservice-default -n gitlab --address 0.0.0.0 8887:8181 2>&1 >/dev/null &
  echo -e "${GREEN}GitLab is accessible at http://localhost:8887${RESET}"
fi

print_header "Deployment Complete! Everything is Set Up."
