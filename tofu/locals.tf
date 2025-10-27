locals {
  # OCI resource IDs
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  ubuntu_image_id     = data.oci_core_images.ubuntu.images[0].id
  ssh_public_key      = file(pathexpand(var.ssh_public_key_path))

  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = "development"
    ManagedBy   = "OpenTofu"
  }

  # Cluster configuration
  cluster_name = "k3s-ha-cluster"
  total_nodes  = var.k3d_masters + var.k3d_workers
  cluster_info = "${var.k3d_masters}m+${var.k3d_workers}w"

  # Security list ports
  public_ports = {
    ssh         = 22
    http        = 80
    https       = 443
    k3s_api     = 6443
    code_server = 8080
  }

  internal_ports = {
    kubelet = 10250
    flannel = 8472
    metrics = 10254
  }
}
