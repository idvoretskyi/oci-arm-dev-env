# OCI ARM Dev Environment

K3d HA Kubernetes cluster on Oracle Cloud's Always Free tier (4 vCPUs, 24GB RAM, $0/month).

## Quick Start

```bash
# Install OpenTofu
brew install opentofu

# Setup
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your OCI credentials

# Deploy
./deploy.sh

# Destroy
./deploy.sh destroy
```

## Prerequisites

- [OCI Always Free account](https://www.oracle.com/cloud/free/)
- OCI config at `~/.oci/config`
- SSH key at `~/.ssh/id_ed25519.pub` (or configure in terraform.tfvars)

## What You Get

- Single ARM VM: 4 vCPUs, 24GB RAM
- K3d cluster: 3 masters + 3 workers (HA)
- Tools: Docker, kubectl, Helm
- Cost: $0/month

## Configuration

Edit `terraform.tfvars`:

```hcl
tenancy_ocid        = "ocid1.tenancy..."
user_ocid           = "ocid1.user..."
fingerprint         = "aa:bb:cc:..."
private_key_path    = "~/.oci/oci_api_key.pem"
region              = "uk-london-1"
compartment_id      = "ocid1.tenancy..."
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
vm_username         = "ubuntu"
```

## Connect

```bash
ssh ubuntu@<instance-ip>

# On the VM
kubectl get nodes
k3d cluster list
```

Wait 5-10 minutes after deployment for cluster setup to complete.

## License

MIT
