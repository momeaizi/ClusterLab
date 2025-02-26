#!/bin/bash

# Define colors
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'

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

# Update system packages
print_header "Updating System Packages"
sudo apt-get update && sudo apt-get upgrade -y || handle_error "Failed to update system packages."

# Install Docker if not installed
print_header "Checking & Installing Docker (Required for k3d)"
if ! command -v docker &> /dev/null; then
  sudo apt install docker.io -y || handle_error "Docker installation failed."
  status_msg "Docker installed successfully."
else
  status_msg "Docker is already installed."
fi

# Install k3d (Lightweight Kubernetes Cluster)
print_header "Checking & Installing k3d (Kubernetes in Docker)"
if ! command -v k3d &> /dev/null; then
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash || handle_error "k3d installation failed."
  status_msg "k3d installed successfully."
else
  status_msg "k3d is already installed."
fi

# Install kubectl (Kubernetes CLI)
print_header "Checking & Installing kubectl (Kubernetes CLI)"
if ! command -v kubectl &> /dev/null; then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" || handle_error "Failed to download kubectl."
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl || handle_error "kubectl installation failed."
  status_msg "kubectl installed successfully."
else
  status_msg "kubectl is already installed."
fi

print_header "Setup Complete! k3d, k3s, and kubectl are Ready."
