# OCI ARM Development Environment

Deploy a complete development environment on Oracle Cloud Infrastructure ARM instances using the Always Free tier. Includes K3d HA Kubernetes cluster and code-server (VS Code in browser).

## What You Get

- **OCI ARM Instance**: 4 vCPUs, 24GB RAM (Always Free tier max)
- **K3d HA Cluster**: 3 master + 3 worker nodes in containers
- **Code-Server**: VS Code in your browser
- **Terraform/OpenTofu**: Choose your IaC tool
- **Ansible**: Automated configuration
- **Helm**: Application deployment

## Quick Start

```bash
# 1. Deploy infrastructure
./deploy.sh deploy              # Using Terraform
# OR
TOFU=true ./deploy.sh deploy    # Using OpenTofu

# 2. Deploy code-server
./deploy-code-server.sh

# 3. Access VS Code in browser
kubectl port-forward -n code-server svc/code-server-service 8080:8080
# Open http://localhost:8080
```

## Prerequisites

**OCI Account**: Set up [Always Free tier](https://www.oracle.com/cloud/free/)

**Local Tools** (macOS):
```bash
brew install terraform kubectl ansible
# OR
brew install opentofu kubectl ansible
```

**OCI Configuration**: Ensure `~/.oci/config` exists with your credentials

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

This deploys:
- OCI infrastructure (VCN, subnet, ARM instance)
- K3d HA cluster (6 nodes: 3 masters + 3 workers)
- Docker, kubectl, Helm, development tools

### 3. Deploy Code-Server

```bash
./deploy-code-server.sh
```

### 4. Access

```bash
kubectl port-forward -n code-server svc/code-server-service 8080:8080
```

Open http://localhost:8080 (default password in `helm-chart/code-server/values.yaml`)

## Common Commands

### Infrastructure

```bash
./deploy.sh deploy       # Full deployment
./deploy.sh configure    # Update configuration only
./deploy.sh output       # Show connection info
./deploy.sh destroy      # Destroy everything
```

### Code-Server

```bash
./deploy-code-server.sh status    # Check status
./deploy-code-server.sh logs      # View logs
./deploy-code-server.sh upgrade   # Upgrade
./deploy-code-server.sh delete    # Remove
```

### Cluster Management

SSH to instance, then:

```bash
kubectl get nodes -o wide                   # View 6 nodes
kubectl get pods -n kube-system             # System pods
k3d cluster list                            # K3d clusters
k3d node create worker --cluster k3s-ha-cluster --role agent  # Add worker
```

## Configuration

### Change Code-Server Password

```bash
helm upgrade code-server ./helm-chart/code-server -n code-server \
  --set codeServer.password=your-new-password
```

### Customize Infrastructure

Edit auto-generated `terraform/terraform.tfvars`:

```hcl
instance_ocpus          = 4     # vCPUs
instance_memory_in_gbs  = 24    # RAM
k3d_nodes              = 6     # Total K3d nodes
k3d_masters            = 3     # Masters (odd number)
k3d_workers            = 3     # Workers
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

### Check Code-Server

```bash
kubectl get pods -n code-server
kubectl logs -n code-server deployment/code-server
```

### Common Issues

**K3d not ready**: Wait 10-15 minutes after deployment for cluster initialization

**Can't access code-server**: Use direct port-forward:
```bash
kubectl port-forward -n code-server pod/<pod-name> 8080:8080
```

**Connection refused**: Check if instance is running in OCI console

## Architecture

Single ARM instance with containerized K3d cluster:

```
OCI ARM Instance (4 vCPUs, 24GB RAM)
├── Docker
│   └── K3d Cluster
│       ├── 3 Masters (HA control plane)
│       └── 3 Workers (workload distribution)
├── Code-Server (VS Code)
└── Storage (Docker volumes)
```

**Benefits:**
- HA Kubernetes on single VM (no extra cost)
- Production-like HA patterns
- Always Free tier maximized
- Fast container deployment

## Cost

**$0/month** - Uses only OCI Always Free tier:
- 4 OCPUs ARM compute
- 24GB RAM
- 200GB storage
- 10TB monthly outbound

## Security

- SSH key authentication only
- Firewall configured (UFW)
- Security lists limit ports: 22, 80, 443, 6443, 8080
- Change default code-server password!

## Documentation

- `ARCHITECTURE.md` - System design
- `SECURITY.md` - Security practices

## License

MIT License - See [LICENSE](LICENSE) file
