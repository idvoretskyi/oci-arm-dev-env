#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
OCI_CONFIG_FILE="$HOME/.oci/config"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
TOFU_DIR="./tofu"

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

read_oci_config() {
    if [ ! -f "$OCI_CONFIG_FILE" ]; then
        print_error "OCI config file not found at $OCI_CONFIG_FILE"
        exit 1
    fi

    print_info "Reading OCI configuration from $OCI_CONFIG_FILE"

    TENANCY_OCID=$(grep "tenancy" "$OCI_CONFIG_FILE" | cut -d'=' -f2)
    USER_OCID=$(grep "user" "$OCI_CONFIG_FILE" | cut -d'=' -f2)
    FINGERPRINT=$(grep "fingerprint" "$OCI_CONFIG_FILE" | cut -d'=' -f2)
    PRIVATE_KEY_PATH=$(grep "key_file" "$OCI_CONFIG_FILE" | cut -d'=' -f2)
    REGION=$(grep "region" "$OCI_CONFIG_FILE" | cut -d'=' -f2)

    PRIVATE_KEY_PATH=$(eval echo "$PRIVATE_KEY_PATH")

    print_info "Tenancy: $TENANCY_OCID"
    print_info "Region: $REGION"
}

validate_prerequisites() {
    print_info "Validating prerequisites..."

    if ! command -v tofu &> /dev/null; then
        print_error "OpenTofu is not installed."
        print_info "Install: brew install opentofu"
        exit 1
    fi

    if ! command -v oci &> /dev/null; then
        print_warning "OCI CLI not installed (recommended but not required)"
    fi

    if [ ! -f "$SSH_KEY_PATH" ]; then
        print_error "SSH public key not found at $SSH_KEY_PATH"
        exit 1
    fi

    if [ ! -f "$PRIVATE_KEY_PATH" ]; then
        print_error "OCI private key not found at $PRIVATE_KEY_PATH"
        exit 1
    fi

    print_info "Prerequisites validated"
}

get_compartment_id() {
    print_info "Getting compartment ID..."

    if command -v oci &> /dev/null; then
        COMPARTMENT_ID=$(oci iam compartment list --all --compartment-id-in-subtree true \
            --access-level ACCESSIBLE --include-root \
            --query "data[?\"lifecycle-state\"=='ACTIVE' && \"name\"=='root'].id | [0]" \
            --raw-output 2>/dev/null || echo "")

        if [ -z "$COMPARTMENT_ID" ]; then
            COMPARTMENT_ID="$TENANCY_OCID"
            print_warning "Using tenancy OCID as compartment ID"
        fi
    else
        COMPARTMENT_ID="$TENANCY_OCID"
        print_warning "Using tenancy OCID as compartment ID"
    fi

    print_info "Compartment ID: $COMPARTMENT_ID"
}

create_tfvars() {
    print_info "Creating terraform.tfvars..."

    cat > "$TOFU_DIR/terraform.tfvars" << EOF
tenancy_ocid        = "$TENANCY_OCID"
user_ocid           = "$USER_OCID"
fingerprint         = "$FINGERPRINT"
private_key_path    = "$PRIVATE_KEY_PATH"
region              = "$REGION"
compartment_id      = "$COMPARTMENT_ID"
ssh_public_key_path = "$SSH_KEY_PATH"
vm_username         = "$(whoami)"

# Instance configuration (Always Free tier maximum)
instance_ocpus          = 4
instance_memory_in_gbs  = 24
boot_volume_size_in_gbs = 50

# K3d HA cluster configuration
k3d_masters = 3
k3d_workers = 3
EOF

    print_info "terraform.tfvars created"
}

deploy_infrastructure() {
    print_info "Deploying infrastructure with OpenTofu..."
    cd "$TOFU_DIR"

    print_info "Initializing OpenTofu..."
    tofu init

    print_info "Planning deployment..."
    tofu plan

    read -p "Proceed with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi

    print_info "Applying deployment..."
    tofu apply -auto-approve

    print_info "Deployment completed!"
    tofu output

    cd - > /dev/null
}

show_connection_info() {
    print_info "Getting connection information..."
    cd "$TOFU_DIR"

    K3D_VM_IP=$(tofu output -raw k3d_vm_public_ip)
    SSH_COMMAND=$(tofu output -raw ssh_command)
    KUBECONFIG_COMMAND=$(tofu output -raw kubeconfig_command)

    echo
    print_info "=== K3D HA CLUSTER CONNECTION ==="
    echo "VM IP: $K3D_VM_IP"
    echo "SSH: $SSH_COMMAND"
    echo "Kubeconfig: $KUBECONFIG_COMMAND"
    echo
    print_info "Wait 10-15 minutes for K3d cluster setup to complete"
    print_info "Then check cluster status:"
    echo "  kubectl get nodes -o wide"
    echo "  k3d cluster list"

    cd - > /dev/null
}

main() {
    print_info "Starting OCI ARM Development Environment deployment..."

    read_oci_config
    validate_prerequisites
    get_compartment_id
    create_tfvars
    deploy_infrastructure
    show_connection_info

    print_info "Deployment process completed!"
}

case "${1:-}" in
    "deploy")
        main
        ;;
    "destroy")
        print_info "Destroying infrastructure..."
        cd "$TOFU_DIR"
        tofu destroy -auto-approve
        cd - > /dev/null
        print_info "Infrastructure destroyed!"
        ;;
    "output")
        print_info "Showing outputs..."
        cd "$TOFU_DIR"
        tofu output
        cd - > /dev/null
        ;;
    "")
        main
        ;;
    *)
        echo "Usage: $0 [deploy|destroy|output]"
        echo "  deploy:  Deploy infrastructure (default)"
        echo "  destroy: Destroy infrastructure"
        echo "  output:  Show outputs"
        exit 1
        ;;
esac
