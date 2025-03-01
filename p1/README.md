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

### 1. Vagrantfile Breakdown

```ruby
# Global Variables
MASTER_IP = "192.168.56.110"    # Server IP address
WORKER_IP = "192.168.56.111"    # Worker IP address
MASTER_NAME = "abouchfaS"       # Server hostname
WORKER_NAME = "abouchfaSW"      # Worker hostname

Vagrant.configure("2") do |config|
  # Server Node Configuration
  config.vm.define MASTER_NAME do |master|
    master.vm.box = "ubuntu/focal64"  # Ubuntu 20.04 LTS
    master.vm.hostname = MASTER_NAME
    master.vm.network "private_network", ip: MASTER_IP
    
    # VirtualBox-specific settings
    master.vm.provider "virtualbox" do |vb|
      vb.name = MASTER_NAME
      vb.memory = 1024    # RAM allocation
      vb.cpus = 1         # CPU allocation
    end

    # Provisioning script with environment variables
    master.vm.provision "shell", path: "scripts/master.sh", env: {
      "MASTER_IP" => MASTER_IP,
      "NODE_TOKEN_FILE" => "/vagrant/node-token"
    }
  end

  # Worker Node Configuration (similar structure)
  config.vm.define WORKER_NAME do |worker|
    # ... similar configuration ...
  end
end
```

### 2. Server Node Provisioning (master.sh)

```bash
# System Updates
apt-get update
apt-get upgrade -y

# Required Packages
apt-get install -y curl openssh-server

# K3s Installation (Server Mode)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--bind-address=${MASTER_IP} --node-external-ip=${MASTER_IP}" sh -

# Node Token Generation
cat /var/lib/rancher/k3s/server/node-token > /vagrant/node-token

# Kubectl Setup
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# SSH Configuration
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
ssh-keygen -t rsa -N "" -f /home/vagrant/.ssh/id_rsa
cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
```

### 3. Worker Node Provisioning (worker.sh)

```bash
# System Updates (similar to server)

# K3s Installation (Agent Mode)
curl -sfL https://get.k3s.io | K3S_URL="https://${MASTER_IP}:6443" K3S_TOKEN=$(cat /vagrant/node-token) sh -

# SSH Configuration (similar to server)
```

## How It Works

1. **Initialization**
   - Vagrant reads the Vagrantfile
   - Creates two virtual machines with specified resources
   - Assigns IP addresses and hostnames

2. **Server Node Setup**
   - Updates system packages
   - Installs K3s in server mode
   - Generates node token for worker
   - Configures SSH access
   - Sets up kubectl

3. **Worker Node Setup**
   - Updates system packages
   - Waits for server node token
   - Joins K3s cluster as agent
   - Configures SSH access

4. **Networking**
   - Private network (192.168.56.0/24)
   - eth0: NAT (internet access)
   - eth1: Host-only (inter-VM communication)

## Troubleshooting

### Common Issues:

1. **VirtualBox Network Issues**
   - Solution: Ensure no IP conflicts
   - Check VirtualBox network settings

2. **K3s Token Issues**
   - Solution: Verify token file exists in /vagrant
   - Check file permissions

3. **SSH Access Problems**
   - Solution: Verify key generation
   - Check authorized_keys permissions

### Verification Commands:

```bash
# Check node status
kubectl get nodes

# Verify SSH access
ssh vagrant@192.168.56.111 -i ~/.ssh/id_rsa

# Check K3s service
systemctl status k3s     # On server
systemctl status k3s-agent  # On worker
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