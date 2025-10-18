# OCI ARM Development Environment

Deploy a K3d HA Kubernetes cluster on Oracle Cloud Infrastructure ARM instances using the Always Free tier. Perfect for development and testing with VS Code Remote SSH or tunnel.

## What You Get

- **OCI ARM Instance**: 4 vCPUs, 24GB RAM (Always Free tier max)
- **K3d HA Cluster**: 3 master + 3 worker nodes in containers
- **Terraform/OpenTofu**: Choose your IaC tool
- **Docker, kubectl, Helm**: Pre-installed development tools
- **VS Code Ready**: Use Remote SSH or tunnel to connect

## Quick Start

```bash
# Deploy infrastructure
./deploy.sh deploy              # Using Terraform
# OR
TOFU=true ./deploy.sh deploy    # Using OpenTofu

# Connect with VS Code
code --remote ssh-remote+$USER@<instance-ip> /path/to/workspace
```

## Prerequisites

**OCI Account**: Set up [Always Free tier](https://www.oracle.com/cloud/free/)

**Local Tools** (macOS):
```bash
brew install terraform
# OR
brew install opentofu
```

**OCI Configuration**: Ensure `~/.oci/config` exists with your credentials

**VS Code** (optional): Install [Remote - SSH extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)

## Installation

### 1. Clone Repository

```bash
git clone https://github.com/idvoretskyi/oci-arm-dev-env.git
cd oci-arm-dev-env
```

### 2. Deploy

```bash
./deploy.sh deploy
```

This will:
1. Provision OCI infrastructure (VCN, subnet, ARM instance)
2. Install Docker, K3d, kubectl, Helm via cloud-init
3. Create K3d HA cluster (3 masters + 3 workers)
4. Configure development environment

Wait 10-15 minutes for cloud-init to complete the setup.

### 3. Connect

**Via SSH:**
```bash
ssh $USER@<instance-ip>
```

**Via VS Code Remote SSH:**
```bash
code --remote ssh-remote+$USER@<instance-ip> /home/$USER
```

**Via VS Code Tunnel:**
```bash
# On the instance
code tunnel
# Follow the prompts to authenticate
```

## Common Commands

### Infrastructure

```bash
./deploy.sh deploy       # Full deployment
./deploy.sh output       # Show connection info
./deploy.sh destroy      # Destroy everything

# Using OpenTofu
TOFU=true ./deploy.sh deploy
TOFU=true ./deploy.sh destroy
```

### Cluster Management

```bash
# SSH to instance
ssh $USER@<instance-ip>

# View cluster
kubectl get nodes -o wide                   # View 6 nodes
kubectl get pods -n kube-system             # System pods
k3d cluster list                            # K3d clusters

# Scale cluster
k3d node create worker --cluster k3s-ha-cluster --role agent  # Add worker
k3d node delete <node-name>                 # Remove node
```

## Configuration

Edit auto-generated `terraform/terraform.tfvars`:

```hcl
instance_ocpus          = 4     # vCPUs (Always Free max)
instance_memory_in_gbs  = 24    # RAM (Always Free max)
k3d_nodes              = 6     # Total K3d nodes
k3d_masters            = 3     # Masters (odd number for quorum)
k3d_workers            = 3     # Workers
boot_volume_size_in_gbs = 50    # Storage
```

## Troubleshooting

### Check Cluster

```bash
# SSH to instance
ssh $USER@<instance-ip>

# Check K3d
k3d cluster list
kubectl get nodes -o wide

# Check logs
sudo cat /var/log/cloud-init-output.log
```

### Common Issues

**K3d not ready**: Wait 10-15 minutes after deployment for cluster initialization

**SSH connection refused**: Check if instance is running in OCI console

**VS Code can't connect**: Ensure your SSH key is added:
```bash
ssh-add ~/.ssh/id_ed25519
```

## Architecture

Single ARM instance with containerized K3d cluster:

```
OCI ARM Instance (4 vCPUs, 24GB RAM)
├── Docker Engine
│   └── K3d HA Cluster
│       ├── 3 Masters (HA control plane with etcd quorum)
│       └── 3 Workers (workload distribution)
├── Development Tools (kubectl, Helm, Docker CLI)
└── Storage (Docker volumes for persistence)
```

**Benefits:**
- HA Kubernetes on single VM (no extra cost)
- Production-like HA patterns
- Always Free tier maximized
- Fast container deployment
- VS Code Remote SSH/Tunnel ready

## Cost

**$0/month** - Uses only OCI Always Free tier:
- 4 OCPUs ARM compute
- 24GB RAM
- 200GB storage
- 10TB monthly outbound

## Security

- SSH key authentication only
- Firewall configured (UFW)
- Security lists limit ports: 22, 80, 443, 6443
- No password-based authentication

## Documentation

- `ARCHITECTURE.md` - System design
- `SECURITY.md` - Security practices

## License

MIT License - See [LICENSE](LICENSE) file
