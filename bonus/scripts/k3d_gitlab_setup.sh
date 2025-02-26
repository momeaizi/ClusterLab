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

# Install Helm if not installed
print_header "Checking and Installing Helm"
if ! command -v helm &> /dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash || handle_error "Failed to install Helm"
  status_msg "Helm installed successfully"
else
  status_msg "Helm is already installed"
fi

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

# Port-forward to access GitLab
print_header "Setting Up Port Forwarding to Access GitLab"
if pgrep -f "kubectl port-forward svc/my-gitlab-webservice-default" > /dev/null; then
  status_msg "Port forwarding is already set up."
else
  kubectl --kubeconfig $CONFIG port-forward svc/my-gitlab-webservice-default -n gitlab --address 0.0.0.0 8887:8181 2>&1 >/dev/null &
  status_msg "GitLab UI is now accessible."
fi

# Display GitLab access information
print_header "GitLab Access Credentials"
export GITLAB_PASSWORD=$(kubectl --kubeconfig $CONFIG get secret my-gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 --decode) || handle_error "Failed to retrieve GitLab initial root password"
echo -e "${GREEN}URL:      http://localhost:8887${RESET}"
echo -e "${GREEN}Username: root${RESET}"
echo -e "${GREEN}Password: $GITLAB_PASSWORD${RESET}"

print_header "Deployment Complete! GitLab is Ready."

