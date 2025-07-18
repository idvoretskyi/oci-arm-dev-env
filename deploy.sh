#!/bin/bash

# OCI K3s Code Server ARM Deployment Script
# This script reads OCI config dynamically and deploys the infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
OCI_CONFIG_FILE="$HOME/.oci/config"
OCI_PROFILE="DEFAULT"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519.pub"
TERRAFORM_DIR="./terraform"

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

# Function to read OCI config
read_oci_config() {
    if [ ! -f "$OCI_CONFIG_FILE" ]; then
        print_error "OCI config file not found at $OCI_CONFIG_FILE"
        exit 1
    fi

    print_info "Reading OCI configuration from $OCI_CONFIG_FILE"
    
    # Read config values
    TENANCY_OCID=$(grep "tenancy" "$OCI_CONFIG_FILE" | cut -d'=' -f2)
    USER_OCID=$(grep "user" "$OCI_CONFIG_FILE" | cut -d'=' -f2)
    FINGERPRINT=$(grep "fingerprint" "$OCI_CONFIG_FILE" | cut -d'=' -f2)
    PRIVATE_KEY_PATH=$(grep "key_file" "$OCI_CONFIG_FILE" | cut -d'=' -f2)
    REGION=$(grep "region" "$OCI_CONFIG_FILE" | cut -d'=' -f2)
    
    # Expand tilde in private key path
    PRIVATE_KEY_PATH=$(eval echo "$PRIVATE_KEY_PATH")
    
    print_info "Tenancy OCID: $TENANCY_OCID"
    print_info "User OCID: $USER_OCID"
    print_info "Region: $REGION"
    print_info "Private Key Path: $PRIVATE_KEY_PATH"
}

# Function to validate prerequisites
validate_prerequisites() {
    print_info "Validating prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if OCI CLI is installed
    if ! command -v oci &> /dev/null; then
        print_warning "OCI CLI is not installed. It's recommended but not required."
    fi
    
    # Check if SSH key exists
    if [ ! -f "$SSH_KEY_PATH" ]; then
        print_error "SSH public key not found at $SSH_KEY_PATH"
        exit 1
    fi
    
    # Check if private key exists
    if [ ! -f "$PRIVATE_KEY_PATH" ]; then
        print_error "OCI private key not found at $PRIVATE_KEY_PATH"
        exit 1
    fi
    
    print_info "All prerequisites validated successfully"
}

# Function to get compartment ID
get_compartment_id() {
    print_info "Getting compartment ID..."
    
    if command -v oci &> /dev/null; then
        # Try to get root compartment ID using OCI CLI
        COMPARTMENT_ID=$(oci iam compartment list --all --compartment-id-in-subtree true --access-level ACCESSIBLE --include-root --query "data[?\"lifecycle-state\"=='ACTIVE' && \"name\"=='root'].id | [0]" --raw-output 2>/dev/null || echo "")
        
        if [ -z "$COMPARTMENT_ID" ]; then
            # Fallback to tenancy OCID as compartment ID
            COMPARTMENT_ID="$TENANCY_OCID"
            print_warning "Could not determine compartment ID, using tenancy OCID as compartment ID"
        fi
    else
        # Use tenancy OCID as compartment ID
        COMPARTMENT_ID="$TENANCY_OCID"
        print_warning "OCI CLI not available, using tenancy OCID as compartment ID"
    fi
    
    print_info "Compartment ID: $COMPARTMENT_ID"
}

# Function to create terraform.tfvars
create_tfvars() {
    print_info "Creating terraform.tfvars file..."
    
    cat > "$TERRAFORM_DIR/terraform.tfvars" << EOF
tenancy_ocid     = "$TENANCY_OCID"
user_ocid        = "$USER_OCID"
fingerprint      = "$FINGERPRINT"
private_key_path = "$PRIVATE_KEY_PATH"
region           = "$REGION"
compartment_id   = "$COMPARTMENT_ID"
ssh_public_key_path = "$SSH_KEY_PATH"
vm_username      = "$(whoami)"

# Instance configuration
instance_shape           = "VM.Standard.A1.Flex"
instance_ocpus          = 2
instance_memory_in_gbs  = 12
boot_volume_size_in_gbs = 50

# K3s cluster configuration
master_nodes = 1
worker_nodes = 2
EOF
    
    print_info "terraform.tfvars created successfully"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_info "Deploying infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    print_info "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_info "Planning Terraform deployment..."
    terraform plan
    
    # Ask for confirmation
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled."
        exit 0
    fi
    
    # Apply deployment
    print_info "Applying Terraform deployment..."
    terraform apply -auto-approve
    
    # Show outputs
    print_info "Deployment completed! Here are the outputs:"
    terraform output
    
    cd - > /dev/null
}

# Function to show connection info
show_connection_info() {
    print_info "Getting connection information..."
    
    cd "$TERRAFORM_DIR"
    
    MASTER_IP=$(terraform output -raw master_public_ips | sed 's/\[//g' | sed 's/\]//g' | sed 's/"//g' | cut -d',' -f1)
    SSH_COMMAND=$(terraform output -raw ssh_command_master)
    KUBECONFIG_COMMAND=$(terraform output -raw kubeconfig_command)
    
    echo
    print_info "=== CONNECTION INFORMATION ==="
    echo "Master node IP: $MASTER_IP"
    echo "SSH to master: $SSH_COMMAND"
    echo "Get kubeconfig: $KUBECONFIG_COMMAND"
    echo
    print_info "After deployment, wait 5-10 minutes for K3s installation to complete."
    print_info "Then you can connect to the master node and check cluster status with:"
    echo "  kubectl get nodes"
    echo "  kubectl get pods --all-namespaces"
    
    cd - > /dev/null
}

# Main execution
main() {
    print_info "Starting OCI K3s Code Server ARM deployment..."
    
    # Read OCI configuration
    read_oci_config
    
    # Validate prerequisites
    validate_prerequisites
    
    # Get compartment ID
    get_compartment_id
    
    # Create terraform.tfvars
    create_tfvars
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Show connection info
    show_connection_info
    
    print_info "Deployment process completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "destroy")
        print_info "Destroying infrastructure..."
        cd "$TERRAFORM_DIR"
        terraform destroy -auto-approve
        cd - > /dev/null
        print_info "Infrastructure destroyed successfully!"
        ;;
    "output")
        print_info "Showing Terraform outputs..."
        cd "$TERRAFORM_DIR"
        terraform output
        cd - > /dev/null
        ;;
    "")
        main
        ;;
    *)
        echo "Usage: $0 [destroy|output]"
        echo "  destroy: Destroy the infrastructure"
        echo "  output:  Show Terraform outputs"
        echo "  (no args): Deploy infrastructure"
        exit 1
        ;;
esac