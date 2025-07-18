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

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "vm_username" {
  description = "Username for the VM"
  type        = string
  default     = "ubuntu"
}

variable "availability_domain" {
  description = "Availability domain for the instances"
  type        = string
  default     = ""
}

variable "instance_shape" {
  description = "Instance shape for ARM instances"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs for the instance (max 4 for Always Free)"
  type        = number
  default     = 4
}

variable "instance_memory_in_gbs" {
  description = "Memory in GBs for the instance (max 24 for Always Free)"
  type        = number
  default     = 24
}

variable "k3d_nodes" {
  description = "Total number of K3d nodes (masters + workers)"
  type        = number
  default     = 6
}

variable "k3d_masters" {
  description = "Number of K3d master nodes (HA - should be odd number)"
  type        = number
  default     = 3
}

variable "k3d_workers" {
  description = "Number of K3d worker nodes (HA)"
  type        = number
  default     = 3
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GBs"
  type        = number
  default     = 50
}