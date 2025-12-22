output "ip" {
  value = oci_core_instance.main.public_ip
}

output "ssh" {
  value = "ssh ${var.vm_username}@${oci_core_instance.main.public_ip}"
}

output "k3d_api" {
  value = "https://${oci_core_instance.main.public_ip}:6443"
}
