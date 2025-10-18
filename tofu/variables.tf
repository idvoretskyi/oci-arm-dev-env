# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "compartment_id" {
  description = "The OCID of the compartment where resources will be created"
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "The compartment_id must be a valid OCI compartment or tenancy OCID."
  }
}

# =============================================================================
# OCI CONFIGURATION
# =============================================================================

variable "tenancy_ocid" {
  description = "OCID of the tenancy"
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.tenancy\\.", var.tenancy_ocid))
    error_message = "The tenancy_ocid must be a valid OCI tenancy OCID."
  }
}

variable "user_ocid" {
  description = "OCID of the user"
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.user\\.", var.user_ocid))
    error_message = "The user_ocid must be a valid OCI user OCID."
  }
}

variable "fingerprint" {
  description = "Fingerprint of the API key"
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{2}(:[0-9a-f]{2}){15}$", var.fingerprint))
    error_message = "The fingerprint must be a valid API key fingerprint format."
  }
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string

  validation {
    condition     = can(regex("\\.(pem|key)$", var.private_key_path))
    error_message = "The private_key_path must end with .pem or .key extension."
  }
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "uk-london-1"

  validation {
    condition = contains([
      "uk-london-1", "us-ashburn-1", "us-phoenix-1", "eu-frankfurt-1",
      "ap-mumbai-1", "ap-seoul-1", "ap-sydney-1", "ap-tokyo-1",
      "ca-toronto-1", "sa-saopaulo-1", "uk-gov-london-1"
    ], var.region)
    error_message = "The region must be a valid OCI region."
  }
}

# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "oci-code-server-arm"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "The project_name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be one of: dev, staging, prod."
  }
}

# =============================================================================
# SSH CONFIGURATION
# =============================================================================

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"

  validation {
    condition     = can(regex("\\.(pub)$", var.ssh_public_key_path))
    error_message = "The ssh_public_key_path must end with .pub extension."
  }
}

variable "vm_username" {
  description = "Username for the VM"
  type        = string
  default     = "ubuntu"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_-]*$", var.vm_username))
    error_message = "The vm_username must start with a letter and contain only lowercase letters, numbers, underscores, and hyphens."
  }
}

# =============================================================================
# COMPUTE CONFIGURATION
# =============================================================================

variable "instance_shape" {
  description = "Instance shape for ARM instances"
  type        = string
  default     = "VM.Standard.A1.Flex"

  validation {
    condition     = can(regex("^VM\\.Standard\\.A1\\.Flex$", var.instance_shape))
    error_message = "Currently only VM.Standard.A1.Flex (ARM) instances are supported."
  }
}

variable "instance_ocpus" {
  description = "Number of OCPUs for the instance (max 4 for Always Free)"
  type        = number
  default     = 4

  validation {
    condition     = var.instance_ocpus >= 1 && var.instance_ocpus <= 4
    error_message = "The instance_ocpus must be between 1 and 4 for free tier ARM instances."
  }
}

variable "instance_memory_in_gbs" {
  description = "Memory in GBs for the instance (max 24 for Always Free)"
  type        = number
  default     = 24

  validation {
    condition     = var.instance_memory_in_gbs >= 1 && var.instance_memory_in_gbs <= 24
    error_message = "The instance_memory_in_gbs must be between 1 and 24 for free tier ARM instances."
  }
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GBs"
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_in_gbs >= 47 && var.boot_volume_size_in_gbs <= 200
    error_message = "The boot_volume_size_in_gbs must be between 47 and 200 GB."
  }
}

variable "availability_domain" {
  description = "Availability domain for the instances"
  type        = string
  default     = ""

  validation {
    condition     = var.availability_domain == "" || can(regex("^[A-Za-z0-9-]+:[A-Z]+-[A-Z]+-[0-9]+$", var.availability_domain))
    error_message = "The availability_domain must be empty (auto-select) or a valid OCI availability domain format."
  }
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to the instance"
  type        = bool
  default     = true
}

# =============================================================================
# K3D CLUSTER CONFIGURATION
# =============================================================================

variable "k3d_nodes" {
  description = "Total number of K3d nodes (masters + workers)"
  type        = number
  default     = 6

  validation {
    condition     = var.k3d_nodes >= 3 && var.k3d_nodes <= 10
    error_message = "The k3d_nodes must be between 3 and 10 for practical deployment."
  }
}

variable "k3d_masters" {
  description = "Number of K3d master nodes (HA - should be odd number)"
  type        = number
  default     = 3

  validation {
    condition     = var.k3d_masters >= 1 && var.k3d_masters <= 5 && var.k3d_masters % 2 == 1
    error_message = "The k3d_masters must be an odd number between 1 and 5 for proper etcd quorum."
  }
}

variable "k3d_workers" {
  description = "Number of K3d worker nodes (HA)"
  type        = number
  default     = 3

  validation {
    condition     = var.k3d_workers >= 1 && var.k3d_workers <= 8
    error_message = "The k3d_workers must be between 1 and 8."
  }
}

# =============================================================================
# NETWORKING CONFIGURATION
# =============================================================================

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vcn_cidr, 0))
    error_message = "The vcn_cidr must be a valid CIDR block."
  }
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "The subnet_cidr must be a valid CIDR block."
  }
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "The ssh_allowed_cidr must be a valid CIDR block."
  }
}