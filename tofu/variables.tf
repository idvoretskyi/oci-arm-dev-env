variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" { default = "uk-london-1" }
variable "compartment_id" {}
variable "ssh_public_key_path" { default = "~/.ssh/id_ed25519.pub" }
variable "vm_username" { default = "ubuntu" }
variable "instance_shape" { default = "VM.Standard.A1.Flex" }
variable "instance_ocpus" { default = 4 }
variable "instance_memory_in_gbs" { default = 24 }
variable "boot_volume_size_in_gbs" { default = 50 }
variable "k3d_masters" { default = 3 }
variable "k3d_workers" { default = 3 }