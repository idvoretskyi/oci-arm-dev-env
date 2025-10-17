#!/bin/bash

# OCI ARM Development Environment Deployment Script
# Supports both Terraform and OpenTofu
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

# Detect IaC tool (Terraform or OpenTofu)
if [ "${TOFU:-false}" = "true" ] || command -v tofu &> /dev/null && [ -z "${TF_CLI:-}" ]; then
    IAC_TOOL="tofu"
    print_info() {
        echo -e "${GREEN}[INFO]${NC} $1"
    }
    print_info "Using OpenTofu"
else
    IAC_TOOL="terraform"
fi

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

    # Check if Terraform or OpenTofu is installed
    if ! command -v "$IAC_TOOL" &> /dev/null; then
        print_error "$IAC_TOOL is not installed. Please install Terraform or OpenTofu."
        print_info "Install Terraform: https://www.terraform.io/downloads.html"
        print_info "Install OpenTofu: https://opentofu.org/docs/intro/install/"
        exit 1
    fi

    print_info "Using $IAC_TOOL ($(command -v $IAC_TOOL))"
    
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

# Instance configuration (Always Free tier maximum)
instance_shape           = "VM.Standard.A1.Flex"
instance_ocpus          = 4                    # Maximum for Always Free
instance_memory_in_gbs  = 24                   # Maximum for Always Free
boot_volume_size_in_gbs = 50

# K3d HA cluster configuration
k3d_nodes    = 6     # Total nodes (3 masters + 3 workers)
k3d_masters  = 3     # HA masters (odd number for quorum)
k3d_workers  = 3     # HA workers for load distribution
EOF
    
    print_info "terraform.tfvars created successfully"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_info "Deploying infrastructure with $IAC_TOOL..."

    cd "$TERRAFORM_DIR"

    # Initialize
    print_info "Initializing $IAC_TOOL..."
    $IAC_TOOL init

    # Plan deployment
    print_info "Planning $IAC_TOOL deployment..."
    $IAC_TOOL plan

    # Ask for confirmation
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled."
        exit 0
    fi

    # Apply deployment
    print_info "Applying $IAC_TOOL deployment..."
    $IAC_TOOL apply -auto-approve

    # Show outputs
    print_info "Deployment completed! Here are the outputs:"
    $IAC_TOOL output

    cd - > /dev/null
}

# Function to show connection info
show_connection_info() {
    print_info "Getting connection information..."

    cd "$TERRAFORM_DIR"

    K3D_VM_IP=$($IAC_TOOL output -raw k3d_vm_public_ip)
    SSH_COMMAND=$($IAC_TOOL output -raw ssh_command)
    KUBECONFIG_COMMAND=$($IAC_TOOL output -raw kubeconfig_command)
    
    echo
    print_info "=== K3D HA CLUSTER CONNECTION INFORMATION ==="
    echo "K3d VM IP: $K3D_VM_IP"
    echo "SSH to VM: $SSH_COMMAND"
    echo "Get kubeconfig: $KUBECONFIG_COMMAND"
    echo
    print_info "After deployment, wait 10-15 minutes for K3d HA cluster installation to complete."
    print_info "Then you can connect to the VM and check cluster status with:"
    echo "  kubectl get nodes -o wide    # Should show 3 masters + 3 workers"
    echo "  kubectl get pods -n kube-system"
    echo "  k3d cluster list"
    echo "  k3d node list"
    
    cd - > /dev/null
}

# Main execution
main() {
    print_info "Starting OCI ARM Development Environment deployment..."
    
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

# Function to wait for SSH connectivity
wait_for_ssh() {
    print_info "Waiting for SSH connectivity..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if ssh -i ~/.ssh/id_ed25519 -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${PUBLIC_IP} "echo 'SSH connection successful'" &>/dev/null 2>&1; then
            print_info "SSH connectivity established ✓"
            return 0
        fi
        
        echo -n "."
        sleep 10
        ((attempt++))
    done
    
    print_error "SSH connectivity could not be established after $((max_attempts * 10)) seconds"
    exit 1
}

# Function to update Ansible inventory
update_ansible_inventory() {
    print_info "Updating Ansible inventory with instance IP..."

    cd "$TERRAFORM_DIR"
    PUBLIC_IP=$($IAC_TOOL output -raw k3d_vm_public_ip 2>/dev/null)
    
    if [[ -z "$PUBLIC_IP" ]]; then
        print_error "Could not retrieve public IP from Terraform outputs"
        exit 1
    fi
    
    cd ..
    
    # Update Ansible inventory with the IP
    if [[ -f "ansible/inventory.yml" ]]; then
        sed -i.bak "s/REPLACE_WITH_PUBLIC_IP/${PUBLIC_IP}/g" "ansible/inventory.yml"
        print_info "Updated Ansible inventory with instance IP: ${PUBLIC_IP} ✓"
    fi
}

# Function to configure instance with Ansible
configure_instance() {
    print_info "Configuring instance with Ansible..."
    
    if [[ ! -d "ansible" ]]; then
        print_warning "Ansible directory not found, skipping configuration management"
        return 0
    fi
    
    cd ansible
    
    # Test Ansible connectivity
    print_info "Testing Ansible connectivity..."
    if ! ansible -i inventory.yml all -m ping; then
        print_warning "Ansible connectivity test failed, but continuing..."
    fi
    
    # Run the playbook
    print_info "Running Ansible playbook..."
    ansible-playbook -i inventory.yml playbook.yml
    
    cd ..
    print_info "Ansible configuration completed ✓"
}

# Enhanced main function with Ansible support
main_with_ansible() {
    print_info "Starting OCI ARM Development Environment deployment with configuration management..."
    
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
    
    # Update Ansible inventory
    update_ansible_inventory
    
    # Wait for SSH connectivity
    wait_for_ssh
    
    # Configure instance with Ansible
    configure_instance
    
    # Show connection info
    show_connection_info
    
    print_info "Full deployment process (Infrastructure + Configuration) completed successfully!"
}

# Function for configuration-only updates
configure_only() {
    print_info "Running configuration-only update with Ansible..."

    if [[ ! -d "ansible" ]]; then
        print_error "Ansible directory not found"
        exit 1
    fi

    # Get instance IP
    cd "$TERRAFORM_DIR"
    PUBLIC_IP=$($IAC_TOOL output -raw k3d_vm_public_ip 2>/dev/null)
    
    if [[ -z "$PUBLIC_IP" ]]; then
        print_error "Could not retrieve public IP. Is infrastructure deployed?"
        exit 1
    fi
    
    cd ..
    
    # Test SSH connectivity
    if ! ssh -i ~/.ssh/id_ed25519 -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${PUBLIC_IP} "echo 'SSH connection successful'" &>/dev/null; then
        print_error "SSH connectivity failed. Check if instance is running."
        exit 1
    fi
    
    # Run Ansible configuration
    configure_instance
    
    print_info "Configuration update completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    "deploy")
        main_with_ansible
        ;;
    "configure")
        configure_only
        ;;
    "destroy")
        print_info "Destroying infrastructure..."
        cd "$TERRAFORM_DIR"
        $IAC_TOOL destroy -auto-approve
        cd - > /dev/null
        print_info "Infrastructure destroyed successfully!"
        ;;
    "output")
        print_info "Showing $IAC_TOOL outputs..."
        cd "$TERRAFORM_DIR"
        $IAC_TOOL output
        cd - > /dev/null
        ;;
    "")
        main
        ;;
    *)
        echo "Usage: $0 [deploy|configure|destroy|output]"
        echo "  deploy:    Full deployment (infrastructure + configuration)"
        echo "  configure: Configuration-only update with Ansible"
        echo "  destroy:   Destroy the infrastructure"
        echo "  output:    Show $IAC_TOOL outputs"
        echo "  (no args): Deploy infrastructure only"
        echo ""
        echo "Environment variables:"
        echo "  TOFU=true  Use OpenTofu instead of Terraform"
        echo ""
        echo "Examples:"
        echo "  $0 deploy              # Deploy with Terraform"
        echo "  TOFU=true $0 deploy    # Deploy with OpenTofu"
        exit 1
        ;;
esac