resource "oci_core_instance" "k3s_master" {
  count               = var.master_nodes
  availability_domain = local.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "k3s-master-${count.index + 1}"
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.k3s_subnet.id
    display_name     = "k3s-master-${count.index + 1}-vnic"
    assign_public_ip = true
    hostname_label   = "k3s-master-${count.index + 1}"
  }

  source_details {
    source_type = "image"
    source_id   = local.ubuntu_image_id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init-master.yaml", {
      username = var.vm_username
      node_index = count.index + 1
      ssh_public_key = local.ssh_public_key
    }))
  }

  freeform_tags = {
    "Project" = "k3s-code-server"
    "Type"    = "master"
  }

  timeouts {
    create = "10m"
  }
}

resource "oci_core_instance" "k3s_worker" {
  count               = var.worker_nodes
  availability_domain = local.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "k3s-worker-${count.index + 1}"
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.k3s_subnet.id
    display_name     = "k3s-worker-${count.index + 1}-vnic"
    assign_public_ip = true
    hostname_label   = "k3s-worker-${count.index + 1}"
  }

  source_details {
    source_type = "image"
    source_id   = local.ubuntu_image_id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  metadata = {
    ssh_authorized_keys = local.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/cloud-init-worker.yaml", {
      username = var.vm_username
      node_index = count.index + 1
      master_ip = oci_core_instance.k3s_master[0].private_ip
      ssh_public_key = local.ssh_public_key
    }))
  }

  freeform_tags = {
    "Project" = "k3s-code-server"
    "Type"    = "worker"
  }

  depends_on = [oci_core_instance.k3s_master]

  timeouts {
    create = "10m"
  }
}