data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "ubuntu_images" {
  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_identity_compartments" "root_compartment" {
  compartment_id = var.tenancy_ocid
}

locals {
  # Use the first availability domain if not specified
  availability_domain = var.availability_domain != "" ? var.availability_domain : data.oci_identity_availability_domains.ads.availability_domains[0].name
  
  # Use the most recent Ubuntu 22.04 ARM image
  ubuntu_image_id = data.oci_core_images.ubuntu_images.images[0].id
  
  # SSH public key content
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))
  
  # Total nodes
  total_nodes = var.master_nodes + var.worker_nodes
}