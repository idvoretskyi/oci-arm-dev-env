#!/bin/bash

# Code Server Helm Deployment Script
# This script deploys code-server to the K3s cluster using Helm

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
HELM_CHART_PATH="./helm-chart/code-server"
RELEASE_NAME="code-server"
NAMESPACE="code-server"

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
}

# Check if Helm is available
check_helm() {
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed or not in PATH"
        print_info "Install Helm from: https://helm.sh/docs/intro/install/"
        exit 1
    fi
}

# Check if cluster is accessible
check_cluster() {
    print_info "Checking cluster connectivity..."
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        print_info "Make sure you have copied the kubeconfig from the master node:"
        print_info "  scp idv@<master-ip>:~/.kube/config ~/.kube/config-oci"
        print_info "  export KUBECONFIG=~/.kube/config-oci"
        exit 1
    fi
    
    print_info "Cluster is accessible"
}

# Create persistent volume directory on master node
create_pv_directory() {
    print_info "Creating persistent volume directory..."
    
    # Get master node IP from terraform output
    if [ -f "terraform/terraform.tfstate" ]; then
        MASTER_IP=$(cd terraform && terraform output -raw master_public_ips | sed 's/\[//g' | sed 's/\]//g' | sed 's/"//g' | cut -d',' -f1)
        
        if [ -n "$MASTER_IP" ]; then
            print_info "Creating directory on master node: $MASTER_IP"
            ssh -o StrictHostKeyChecking=no idv@$MASTER_IP "sudo mkdir -p /opt/code-server-data && sudo chown 1000:1000 /opt/code-server-data"
            print_info "Directory created successfully"
        else
            print_warning "Could not determine master IP, please create /opt/code-server-data directory manually"
        fi
    else
        print_warning "Terraform state not found, please create /opt/code-server-data directory manually on master node"
    fi
}

# Deploy code-server using Helm
deploy_code_server() {
    print_info "Deploying code-server to K3s cluster using Helm..."
    
    # Create namespace if it doesn't exist
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    
    # Validate Helm chart
    print_info "Validating Helm chart..."
    helm lint $HELM_CHART_PATH
    
    # Deploy or upgrade with Helm
    if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
        print_info "Upgrading existing release..."
        helm upgrade $RELEASE_NAME $HELM_CHART_PATH -n $NAMESPACE
    else
        print_info "Installing new release..."
        helm install $RELEASE_NAME $HELM_CHART_PATH -n $NAMESPACE
    fi
    
    print_info "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/$RELEASE_NAME -n $NAMESPACE
    
    print_info "Code-server deployed successfully!"
}

# Show deployment status
show_status() {
    print_info "=== CODE-SERVER DEPLOYMENT STATUS ==="
    
    echo
    print_info "Helm Release:"
    helm list -n $NAMESPACE
    
    echo
    print_info "Namespace:"
    kubectl get namespace $NAMESPACE
    
    echo
    print_info "Pods:"
    kubectl get pods -n $NAMESPACE
    
    echo
    print_info "Services:"
    kubectl get services -n $NAMESPACE
    
    echo
    print_info "Ingress:"
    kubectl get ingress -n $NAMESPACE
    
    echo
    print_info "Persistent Volume Claims:"
    kubectl get pvc -n $NAMESPACE
}

# Show access information
show_access_info() {
    print_info "=== ACCESS INFORMATION ==="
    
    # Get service details
    SERVICE_NAME="${RELEASE_NAME}-service"
    SERVICE_IP=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.clusterIP}')
    SERVICE_PORT=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.ports[0].port}')
    
    # Get master node IP
    if [ -f "terraform/terraform.tfstate" ]; then
        MASTER_IP=$(cd terraform && terraform output -raw master_public_ips | sed 's/\[//g' | sed 's/\]//g' | sed 's/"//g' | cut -d',' -f1)
    else
        MASTER_IP="<master-ip>"
    fi
    
    echo
    print_info "Helm Release Notes:"
    helm get notes $RELEASE_NAME -n $NAMESPACE
    
    echo
    print_info "Internal service access:"
    echo "  Service IP: $SERVICE_IP"
    echo "  Service Port: $SERVICE_PORT"
    echo
    print_info "Port forwarding access:"
    echo "  kubectl port-forward -n $NAMESPACE svc/$SERVICE_NAME 8080:8080"
    echo "  Then access: http://localhost:8080"
    echo
    print_info "Direct access via master node:"
    echo "  ssh -L 8080:$SERVICE_IP:$SERVICE_PORT idv@$MASTER_IP"
    echo "  Then access: http://localhost:8080"
    echo
    print_info "To change password:"
    echo "  helm upgrade $RELEASE_NAME $HELM_CHART_PATH -n $NAMESPACE --set codeServer.password=<new-password>"
}

# Main function
main() {
    print_info "Starting code-server deployment to K3s using Helm..."
    
    check_kubectl
    check_helm
    check_cluster
    create_pv_directory
    deploy_code_server
    show_status
    show_access_info
    
    print_info "Code-server deployment completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "delete")
        print_info "Deleting code-server Helm release..."
        helm uninstall $RELEASE_NAME -n $NAMESPACE || true
        kubectl delete namespace $NAMESPACE --ignore-not-found=true
        print_info "Code-server deployment deleted"
        ;;
    "status")
        check_kubectl
        check_helm
        show_status
        ;;
    "access")
        check_kubectl
        check_helm
        show_access_info
        ;;
    "logs")
        check_kubectl
        print_info "Showing code-server logs..."
        kubectl logs -f -n $NAMESPACE deployment/$RELEASE_NAME
        ;;
    "upgrade")
        check_kubectl
        check_helm
        check_cluster
        print_info "Upgrading code-server deployment..."
        helm upgrade $RELEASE_NAME $HELM_CHART_PATH -n $NAMESPACE
        print_info "Code-server upgraded successfully!"
        ;;
    "values")
        print_info "Showing current Helm values..."
        helm get values $RELEASE_NAME -n $NAMESPACE
        ;;
    "")
        main
        ;;
    *)
        echo "Usage: $0 [delete|status|access|logs|upgrade|values]"
        echo "  delete:   Delete code-server deployment"
        echo "  status:   Show deployment status"
        echo "  access:   Show access information"
        echo "  logs:     Show code-server logs"
        echo "  upgrade:  Upgrade existing deployment"
        echo "  values:   Show current Helm values"
        echo "  (no args): Deploy code-server"
        exit 1
        ;;
esac