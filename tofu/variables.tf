# OCI Authentication
variable "tenancy_ocid" {
  description = "OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the API key"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "uk-london-1"
}

variable "compartment_id" {
  description = "OCID of the compartment"
  type        = string
}

# SSH Configuration
variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "vm_username" {
  description = "VM username"
  type        = string
  default     = "ubuntu"
}

# Compute Configuration
variable "instance_shape" {
  description = "Instance shape (Always Free: VM.Standard.A1.Flex)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs (Always Free max: 4)"
  type        = number
  default     = 4

  validation {
    condition     = var.instance_ocpus >= 1 && var.instance_ocpus <= 4
    error_message = "OCPUs must be between 1 and 4 for Always Free tier."
  }
}

variable "instance_memory_in_gbs" {
  description = "Memory in GB (Always Free max: 24)"
  type        = number
  default     = 24

  validation {
    condition     = var.instance_memory_in_gbs >= 1 && var.instance_memory_in_gbs <= 24
    error_message = "Memory must be between 1 and 24 GB for Always Free tier."
  }
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_in_gbs >= 50 && var.boot_volume_size_in_gbs <= 200
    error_message = "Boot volume must be between 50 and 200 GB."
  }
}

# K3d Cluster Configuration
variable "k3d_masters" {
  description = "Number of K3d master nodes (odd number for HA)"
  type        = number
  default     = 3

  validation {
    condition     = var.k3d_masters % 2 == 1 && var.k3d_masters >= 1
    error_message = "Masters must be an odd number (1, 3, 5, etc.) for HA quorum."
  }
}

variable "k3d_workers" {
  description = "Number of K3d worker nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.k3d_workers >= 0
    error_message = "Workers must be 0 or greater."
  }
}

# Networking Configuration
variable "vcn_cidr" {
  description = "VCN CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}

# Project Configuration
variable "project_name" {
  description = "Project name for resource naming and tags"
  type        = string
  default     = "oci-arm-dev-env"
}
