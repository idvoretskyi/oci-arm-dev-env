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
    masters = var.k3d_masters
    workers = var.k3d_workers
    total_nodes = var.k3d_nodes
    cluster_name = "k3s-ha-cluster"
  }
}

output "k3d_api_endpoint" {
  description = "K3d API server endpoint"
  value       = "https://${oci_core_instance.k3d_vm.public_ip}:6443"
}

output "code_server_access" {
  description = "Code-server access URLs"
  value = {
    port_forward = "kubectl port-forward -n code-server svc/code-server-service 8080:8080"
    local_url = "http://localhost:8080"
    ingress_url = "http://${oci_core_instance.k3d_vm.public_ip}:8080"
  }
}

output "vcn_id" {
  description = "VCN ID"
  value       = oci_core_vcn.k3s_vcn.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = oci_core_subnet.k3s_subnet.id
}