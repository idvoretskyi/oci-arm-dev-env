# OCI ARM Development Environment

Deploy a K3d HA Kubernetes cluster on Oracle Cloud Infrastructure using the Always Free tier.

## What You Get

- **OCI ARM Instance**: 4 vCPUs, 24GB RAM (Always Free)
- **K3d HA Cluster**: 3 master + 3 worker nodes
- **Development Tools**: Docker, kubectl, Helm, OpenTofu
- **VS Code Ready**: Remote SSH or tunnel support

## Quick Start

```bash
# Deploy
./deploy.sh deploy

# Connect
ssh $USER@<instance-ip>
```

## Prerequisites

- [OCI Always Free account](https://www.oracle.com/cloud/free/)
- OpenTofu: `brew install opentofu` (macOS)
- OCI config at `~/.oci/config`

## Installation

```bash
# Clone and deploy
git clone https://github.com/idvoretskyi/oci-arm-dev-env.git
cd oci-arm-dev-env
./deploy.sh deploy
```

Wait 10-15 minutes for cloud-init to complete cluster setup.

## Common Commands

```bash
# Infrastructure
./deploy.sh deploy       # Deploy everything
./deploy.sh output       # Show connection info
./deploy.sh destroy      # Destroy all resources

# Cluster (on instance)
kubectl get nodes -o wide
k3d cluster list
k3d node create worker --cluster k3s-ha-cluster --role agent
```

## VS Code Connection

```bash
# Remote SSH
code --remote ssh-remote+$USER@<instance-ip> /home/$USER

# Or use tunnel (on instance)
code tunnel
```

## Configuration

Edit `tofu/terraform.tfvars`:

```hcl
instance_ocpus          = 4     # Max for Always Free
instance_memory_in_gbs  = 24    # Max for Always Free
k3d_masters             = 3     # HA masters (odd number)
k3d_workers             = 3     # HA workers
```

## Troubleshooting

```bash
# Check cluster status
ssh $USER@<instance-ip>
k3d cluster list
kubectl get nodes

# View setup logs
sudo cat /var/log/cloud-init-output.log

# Fix SSH connection
ssh-add ~/.ssh/id_ed25519
```

## Architecture

```
OCI ARM Instance (4 vCPUs, 24GB RAM)
├── Docker Engine
│   └── K3d HA Cluster
│       ├── 3 Masters (etcd quorum)
│       └── 3 Workers (workload distribution)
└── Development Tools
```

## Cost

**$0/month** - Always Free tier includes:
- 4 ARM OCPUs
- 24GB RAM
- 200GB storage
- 10TB outbound transfer

## Security

- SSH key authentication only
- UFW firewall configured
- Ports: 22, 80, 443, 6443
- No password authentication

## License

MIT License - See [LICENSE](LICENSE) file
