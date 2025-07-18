output "master_public_ips" {
  description = "Public IP addresses of K3s master nodes"
  value       = oci_core_instance.k3s_master[*].public_ip
}

output "master_private_ips" {
  description = "Private IP addresses of K3s master nodes"
  value       = oci_core_instance.k3s_master[*].private_ip
}

output "worker_public_ips" {
  description = "Public IP addresses of K3s worker nodes"
  value       = oci_core_instance.k3s_worker[*].public_ip
}

output "worker_private_ips" {
  description = "Private IP addresses of K3s worker nodes"
  value       = oci_core_instance.k3s_worker[*].private_ip
}

output "ssh_command_master" {
  description = "SSH command to connect to the master node"
  value       = "ssh ${var.vm_username}@${oci_core_instance.k3s_master[0].public_ip}"
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig from master node"
  value       = "scp ${var.vm_username}@${oci_core_instance.k3s_master[0].public_ip}:~/.kube/config ~/.kube/config-oci"
}

output "k3s_api_endpoint" {
  description = "K3s API server endpoint"
  value       = "https://${oci_core_instance.k3s_master[0].public_ip}:6443"
}

output "vcn_id" {
  description = "VCN ID"
  value       = oci_core_vcn.k3s_vcn.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = oci_core_subnet.k3s_subnet.id
}