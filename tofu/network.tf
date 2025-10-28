resource "oci_core_vcn" "k3s_vcn" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-vcn"
  cidr_block     = var.vcn_cidr
  dns_label      = "devenv"

  freeform_tags = local.common_tags
}

resource "oci_core_internet_gateway" "k3s_igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.k3s_vcn.id
  display_name   = "${var.project_name}-igw"
  enabled        = true

  freeform_tags = local.common_tags
}

resource "oci_core_route_table" "k3s_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.k3s_vcn.id
  display_name   = "${var.project_name}-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.k3s_igw.id
  }

  freeform_tags = local.common_tags
}

resource "oci_core_subnet" "k3s_subnet" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.k3s_vcn.id
  display_name      = "${var.project_name}-subnet"
  cidr_block        = var.subnet_cidr
  dns_label         = "devsubnet"
  route_table_id    = oci_core_route_table.k3s_rt.id
  security_list_ids = [oci_core_security_list.k3s_seclist.id]
  dhcp_options_id   = oci_core_vcn.k3s_vcn.default_dhcp_options_id

  freeform_tags = local.common_tags
}

resource "oci_core_security_list" "k3s_seclist" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.k3s_vcn.id
  display_name   = "${var.project_name}-seclist"

  # Egress rules
  egress_security_rules {
    destination      = "0.0.0.0/0"
    protocol         = "all"
    destination_type = "CIDR_BLOCK"
  }

  # SSH access
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = local.public_ports.ssh
      max = local.public_ports.ssh
    }
    description = "SSH access"
  }

  # HTTP access
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = local.public_ports.http
      max = local.public_ports.http
    }
    description = "HTTP access"
  }

  # HTTPS access
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = local.public_ports.https
      max = local.public_ports.https
    }
    description = "HTTPS access"
  }

  # K3s API server
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = local.public_ports.k3s_api
      max = local.public_ports.k3s_api
    }
    description = "K3s API server"
  }

  # Code-server
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = local.public_ports.code_server
      max = local.public_ports.code_server
    }
    description = "Code-server"
  }

  # K3s node communication
  ingress_security_rules {
    protocol = "6"
    source   = var.vcn_cidr
    tcp_options {
      min = local.internal_ports.kubelet
      max = local.internal_ports.kubelet
    }
    description = "K3s kubelet"
  }

  # K3s flannel
  ingress_security_rules {
    protocol = "17"
    source   = var.vcn_cidr
    udp_options {
      min = local.internal_ports.flannel
      max = local.internal_ports.flannel
    }
    description = "K3s flannel VXLAN"
  }

  # K3s metrics
  ingress_security_rules {
    protocol = "6"
    source   = var.vcn_cidr
    tcp_options {
      min = local.internal_ports.metrics
      max = local.internal_ports.metrics
    }
    description = "K3s metrics"
  }

  freeform_tags = local.common_tags
}