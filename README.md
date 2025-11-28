# ClusterLab - Cloud-Native GitOps Infrastructure

A comprehensive DevOps infrastructure project demonstrating modern Kubernetes deployment practices using GitOps methodology. This project showcases the complete setup and automation of a local Kubernetes development environment with continuous deployment capabilities.

## 🚀 Features

- **Automated K3s Cluster Provisioning**: Lightweight Kubernetes cluster setup using k3d for efficient local development
- **GitLab CI/CD Integration**: Self-hosted GitLab instance deployed via Helm charts with optimized resource configurations
- **GitOps Implementation**: ArgoCD integration for automated application deployment and synchronization
- **Infrastructure as Code**: Complete automation scripts for reproducible environment setup
- **Self-Healing Deployments**: Automated sync policies with auto-prune capabilities
- **Secure Credential Management**: Automated secret retrieval and display

## 🛠️ Technical Stack

- **Container Orchestration**: Kubernetes (k3s via k3d)
- **GitOps**: ArgoCD
- **CI/CD**: GitLab CE
- **Package Management**: Helm 3
- **Ingress**: NGINX Ingress Controller
- **Container Runtime**: Docker

## 📋 Prerequisites

- Linux-based operating system
- Sudo privileges
- Internet connection for downloading components

## 🎯 Quick Start

Clone the repository and navigate to the scripts directory:

```bash
git clone https://github.com/momeaizi/ClusterLab.git
cd ClusterLab/scripts
```

### 1. Setup Kubernetes Cluster

```bash
./setup_k3d_k3s_kubectl.sh
```

This script will:
- Install Docker (if not present)
- Install k3d
- Install kubectl
- Create a k3d cluster named `my-cluster`
- Generate kubeconfig at `../confs/kubeconfig.yml`

### 2. Deploy GitLab

```bash
./k3d_gitlab_setup.sh
```

This script will:
- Install Helm 3
- Deploy GitLab CE in the `gitlab` namespace
- Wait for all GitLab components to be ready
- Set up port forwarding for GitLab UI
- Display access credentials

**Access GitLab:**
- URL: http://localhost:8887
- Username: `root`
- Password: (displayed in terminal output)

### 3. Setup ArgoCD and Deploy Application

```bash
./argocd_setup.sh
```

This script will:
- Create `dev` and `argocd` namespaces
- Deploy ArgoCD
- Expose ArgoCD UI on port 8088
- Configure application sync from GitLab repository
- Display ArgoCD access credentials

**Access ArgoCD:**
- URL: http://localhost:8088
- Username: `admin`
- Password: (displayed in terminal output)

## 📁 Project Structure

```
ClusterLab/
├── confs/
│   ├── values.yaml              # GitLab Helm chart configuration
│   ├── kubeconfig.yml           # Generated Kubernetes config
│   └── applications/
│       └── application.yaml     # ArgoCD application manifest
├── scripts/
│   ├── setup_k3d_k3s_kubectl.sh # K3s cluster setup
│   ├── k3d_gitlab_setup.sh      # GitLab deployment
│   └── argocd_setup.sh          # ArgoCD setup
└── README.md
```

## 🔧 Configuration Details

### Kubernetes Namespaces

- `gitlab`: GitLab and its components
- `argocd`: ArgoCD server and controllers
- `dev`: Application deployments

### Port Forwarding

- **GitLab UI**: `localhost:8887`
- **ArgoCD UI**: `localhost:8088`
- **GitLab SSH**: `localhost:32022`

### GitLab Configuration

The GitLab deployment is optimized for local development:
- Minimal replica counts (1 replica per service)
- CertManager disabled (self-signed certificates)
- Prometheus disabled (reduced resource usage)
- GitLab Runner disabled
- SSH access via NodePort 32022

### ArgoCD Application Sync

- **Auto-sync**: Enabled
- **Prune**: Enabled (removes resources deleted from Git)
- **Self-heal**: Enabled (reverts manual cluster changes)
- **Source**: GitLab repository at `http://10.0.2.15:8887/root/will42-playground.git`

## 🔐 Security Notes

- Initial passwords are automatically generated and displayed during setup
- Passwords are stored in Kubernetes secrets
- All services are exposed on localhost only
- This setup is designed for local development, not production use

## 🐛 Troubleshooting

### Pods not starting

```bash
kubectl --kubeconfig ../confs/kubeconfig.yml get pods -A
kubectl --kubeconfig ../confs/kubeconfig.yml describe pod <pod-name> -n <namespace>
```

### Check cluster status

```bash
k3d cluster list
kubectl --kubeconfig ../confs/kubeconfig.yml cluster-info
```

### Restart port forwarding

If you can't access GitLab or ArgoCD:

```bash
# For GitLab
kubectl --kubeconfig ../confs/kubeconfig.yml port-forward svc/my-gitlab-webservice-default -n gitlab --address 0.0.0.0 8887:8181 &

# For ArgoCD
kubectl --kubeconfig ../confs/kubeconfig.yml port-forward svc/argocd-server -n argocd --address 0.0.0.0 8088:80 &
```

### Delete and recreate cluster

```bash
k3d cluster delete my-cluster
./setup_k3d_k3s_kubectl.sh
```

## 📚 Learning Outcomes

This project demonstrates:
- Cloud-native application deployment patterns
- GitOps workflow implementation
- Infrastructure automation with shell scripting
- Kubernetes resource management
- Helm chart customization
- CI/CD pipeline integration
- Container orchestration best practices

## 🤝 Contributing

Feel free to fork this project and adapt it to your needs. Contributions and improvements are welcome!

## 📄 License

This project is open source and available for educational purposes.

## 👤 Author

**momeaizi**
- GitHub: [@momeaizi](https://github.com/momeaizi)
- Project: [ClusterLab](https://github.com/momeaizi/ClusterLab)

---

⭐ Star this repository if you find it helpful!
