# OpenTofu configuration for OCI ARM development environment
# This module deploys a K3d HA Kubernetes cluster on OCI ARM Always Free tier

terraform {
  required_version = ">= 1.6"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

# Main infrastructure components are organized in separate files:
# - provider.tf: OCI provider configuration
# - data.tf: Data sources for availability domains and images
# - locals.tf: Local values and computed variables
# - variables.tf: Input variables
# - network.tf: VCN, subnet, security lists, and routing
# - compute.tf: OCI compute instance with cloud-init
# - outputs.tf: Output values for deployed resources
