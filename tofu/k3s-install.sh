#!/bin/bash

# K3s installation script for ARM instances
# This script handles both master and worker node installation

set -e

NODE_TYPE=$1
MASTER_IP=$2
K3S_TOKEN=$3

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget git unzip

# Configure firewall
ufw allow 22/tcp
ufw allow 6443/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8080/tcp
ufw allow 10250/tcp
ufw allow 8472/udp
ufw allow 10254/tcp
ufw --force enable

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# Create directories
mkdir -p /etc/k3s
mkdir -p /var/lib/k3s
chown -R ubuntu:ubuntu /var/lib/k3s

if [ "$NODE_TYPE" = "master" ]; then
    echo "Installing K3s master node..."
    
    # Install K3s server
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644 --disable traefik --disable servicelb --cluster-init" sh -
    
    # Wait for K3s to be ready
    sleep 30
    
    # Get the token
    K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
    echo "K3S_TOKEN: $K3S_TOKEN"
    
    # Create kubeconfig for ubuntu user
    mkdir -p /home/ubuntu/.kube
    cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
    chown ubuntu:ubuntu /home/ubuntu/.kube/config
    
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
    
    # Install Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    # Install Nginx Ingress Controller
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
    
    # Wait for ingress controller to be ready
    kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s
    
else
    echo "Installing K3s worker node..."
    
    # Wait for master to be ready
    sleep 60
    
    # Install K3s agent
    curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${K3S_TOKEN} sh -
    
fi

# Configure systemd service
systemctl enable k3s
systemctl start k3s

# Install additional tools
snap install code --classic

echo "K3s installation completed for $NODE_TYPE node"