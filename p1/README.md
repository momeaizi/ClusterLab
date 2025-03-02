# Part 1: K3s and Vagrant Guide

## Table of Contents
1. [Overview](#overview)
2. [Technologies Used](#technologies-used)
3. [Project Structure](#project-structure)
4. [Detailed Implementation](#detailed-implementation)
5. [How It Works](#how-it-works)
6. [Troubleshooting](#troubleshooting)

## Overview

Part 1 of the Inception-of-Things project focuses on setting up a minimal Kubernetes cluster using K3s and Vagrant. The goal is to create two virtual machines: one server (controller) and one worker node, with specific configurations and automated setup.

### Key Requirements:
- Two virtual machines with minimal resources
- Specific IP addressing and hostname conventions
- Passwordless SSH access between nodes
- K3s installation in controller and agent modes
- Kubectl installation and configuration

## Technologies Used

### 1. Vagrant
- A tool for building and managing virtual machine environments
- Uses declarative configuration files
- Supports multiple providers (VirtualBox in our case)
- Enables automated provisioning

### 2. K3s
- Lightweight Kubernetes distribution
- Perfect for edge computing, IoT, CI, and development
- Packaged as a single binary
- Minimal resource requirements

### 3. VirtualBox
- Hypervisor for running virtual machines
- Provides networking capabilities
- Manages resource allocation

## Project Structure

```
p1/
├── Vagrantfile           # Main configuration file for VMs
├── scripts/
│   ├── master.sh         # Server node provisioning script
│   └── worker.sh         # Worker node provisioning script
└── confs/                # Additional configuration files (if needed)
```

## Detailed Implementation

### 1. Vagrantfile Configuration

#### Global Variables
```ruby
MASTER_IP = "192.168.56.110"    # Server IP address
WORKER_IP = "192.168.56.111"    # Worker IP address
MASTER_NAME = "abouchfaS"       # Server hostname
WORKER_NAME = "abouchfaSW"      # Worker hostname
NODE_TOKEN_FILE = "/vagrant/node-token"
```

These constants are defined for easy configuration and reuse throughout the Vagrantfile.

#### VM Configuration (Both Nodes)
- Uses Debian Bookworm 64-bit as base OS
- Configures private network with static IPs
- Allocates 1GB RAM and 1 CPU per node
- Sets up hostname and VirtualBox-specific settings
- Mounts shared directory for token exchange

#### Environment Variables
- Master node receives: `NODE_TOKEN_FILE`
- Worker node receives: `MASTER_IP` and `NODE_TOKEN_FILE`

### 2. Master Node Provisioning Script (master.sh)

#### System Preparation
```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install curl net-tools -y
```
- Updates package list and system
- Installs required tools (curl for downloads, net-tools for networking)

#### K3s Server Installation
```bash
curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode 644 --flannel-iface=eth1
```
- Downloads and installs K3s in server mode
- Sets kubeconfig permissions to 644 (readable by all)
- Configures Flannel to use eth1 for cluster communication

#### Cluster Readiness Check
```bash
while ! kubectl get node 2>/dev/null; do
    sleep 1
done
```
- Loops until K3s server is operational
- Suppresses errors during checking

#### Token Generation
```bash
cat /var/lib/rancher/k3s/server/node-token > $NODE_TOKEN_FILE
```
- Exports node token for worker authentication
- Saves to shared directory for worker access

### 3. Worker Node Provisioning Script (worker.sh)

#### Token Availability Check
```bash
while [ ! -f $NODE_TOKEN_FILE ]; do
    sleep 1
done
```
- Waits for master node to generate token
- Ensures proper cluster joining sequence

#### K3s Agent Installation
```bash
curl -sfL https://get.k3s.io | K3S_URL="https://${MASTER_IP}:6443" K3S_TOKEN=$(cat $NODE_TOKEN_FILE) sh -s - --flannel-iface=eth1
```
- Installs K3s in agent mode
- Connects to master using provided token
- Uses eth1 for cluster networking
- Port 6443 is the default Kubernetes API server port

## Networking Details

### Network Interfaces
- eth0: NAT interface for internet access
- eth1: Host-only network for inter-VM communication
- Flannel configured to use eth1 for cluster traffic

### Network Configuration
- Private network subnet: 192.168.56.0/24
- Master node: 192.168.56.110
- Worker node: 192.168.56.111
- API Server port: 6443

## Verification and Management

### Cluster Status
```bash
# On master node
kubectl get nodes        # List all nodes
kubectl get pods -A      # List all pods in all namespaces
```

### Service Status
```bash
# On master node
systemctl status k3s

# On worker node
systemctl status k3s-agent
```

### Logs
```bash
# View K3s logs
sudo journalctl -u k3s         # On master
sudo journalctl -u k3s-agent   # On worker
```

## Quick Reference Commands

### Vagrant Management
```bash
vagrant up          # Start cluster
vagrant halt        # Stop cluster
vagrant destroy -f  # Delete cluster
vagrant ssh         # Connect to VMs
```

### Cluster Management
```bash
kubectl get nodes -o wide  # Detailed node info
kubectl get pods -A        # All pods in cluster
kubectl describe node      # Node details
```

## How It Works

1. **Initialization**
   - Vagrant reads the Vagrantfile
   - Creates two virtual machines with specified resources
   - Assigns IP addresses and hostnames

2. **Server Node Setup**
   - Updates system packages and installs required tools (curl, net-tools)
   - Installs K3s in server mode with Flannel configured for eth1
   - Waits for the server to be operational
   - Generates and shares node token for worker

3. **Worker Node Setup**
   - Updates system packages and installs required tools
   - Waits for server node token to be available
   - Joins K3s cluster as agent using the token
   - Configures Flannel to use eth1 for cluster communication

4. **Networking**
   - Private network (192.168.56.0/24)
   - eth0: NAT (internet access)
   - eth1: Host-only (inter-VM communication)

## Verification Commands:

```bash
# Check node status
kubectl get nodes

# Check K3s service
systemctl status k3s     # On server
systemctl status k3s-agent  # On worker

# Check logs
journalctl -u k3s          # On server
journalctl -u k3s-agent    # On worker
```

## Usage

1. Start the cluster:
```bash
vagrant up
```

2. SSH into server:
```bash
vagrant ssh abouchfaS
```

3. Check cluster status:
```bash
kubectl get nodes
```

4. Destroy cluster:
```bash
vagrant destroy -f
``` 