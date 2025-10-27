output "k3d_vm_public_ip" {
  description = "Public IP address of K3d HA cluster VM"
  value       = oci_core_instance.k3d_vm.public_ip
}

output "k3d_vm_private_ip" {
  description = "Private IP address of K3d HA cluster VM"
  value       = oci_core_instance.k3d_vm.private_ip
}

output "ssh_command" {
  description = "SSH command to connect to the K3d VM"
  value       = "ssh ${var.vm_username}@${oci_core_instance.k3d_vm.public_ip}"
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig from K3d VM"
  value       = "scp ${var.vm_username}@${oci_core_instance.k3d_vm.public_ip}:~/.kube/config ~/.kube/config-oci"
}

output "k3d_cluster_info" {
  description = "K3d cluster configuration"
  value = {
    cluster_name = local.cluster_name
    masters      = var.k3d_masters
    workers      = var.k3d_workers
    total_nodes  = local.total_nodes
    info         = local.cluster_info
  }
}

output "k3d_api_endpoint" {
  description = "K3d API server endpoint"
  value       = "https://${oci_core_instance.k3d_vm.public_ip}:6443"
}

output "vcn_id" {
  description = "VCN ID"
  value       = oci_core_vcn.k3s_vcn.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = oci_core_subnet.k3s_subnet.id
}
