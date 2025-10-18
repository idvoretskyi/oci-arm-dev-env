resource "oci_core_vcn" "k3s_vcn" {
  compartment_id = var.compartment_id
  display_name   = "k3s-vcn"
  cidr_block     = "10.0.0.0/16"
  dns_label      = "k3svcn"

  freeform_tags = {
    "Project" = "k3s-code-server"
  }
}

resource "oci_core_internet_gateway" "k3s_igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.k3s_vcn.id
  display_name   = "k3s-igw"
  enabled        = true

  freeform_tags = {
    "Project" = "k3s-code-server"
  }
}

resource "oci_core_route_table" "k3s_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.k3s_vcn.id
  display_name   = "k3s-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.k3s_igw.id
  }

  freeform_tags = {
    "Project" = "k3s-code-server"
  }
}

resource "oci_core_subnet" "k3s_subnet" {
  compartment_id      = var.compartment_id
  vcn_id              = oci_core_vcn.k3s_vcn.id
  display_name        = "k3s-subnet"
  cidr_block          = "10.0.1.0/24"
  dns_label           = "k3ssubnet"
  route_table_id      = oci_core_route_table.k3s_rt.id
  security_list_ids   = [oci_core_security_list.k3s_seclist.id]
  dhcp_options_id     = oci_core_vcn.k3s_vcn.default_dhcp_options_id

  freeform_tags = {
    "Project" = "k3s-code-server"
  }
}

resource "oci_core_security_list" "k3s_seclist" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.k3s_vcn.id
  display_name   = "k3s-seclist"

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
      min = 22
      max = 22
    }
    description = "SSH access"
  }

  # HTTP access
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
    description = "HTTP access"
  }

  # HTTPS access
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
    description = "HTTPS access"
  }

  # K3s API server
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 6443
      max = 6443
    }
    description = "K3s API server"
  }

  # Code-server
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 8080
      max = 8080
    }
    description = "Code-server"
  }

  # K3s node communication
  ingress_security_rules {
    protocol = "6"
    source   = "10.0.0.0/16"
    tcp_options {
      min = 10250
      max = 10250
    }
    description = "K3s kubelet"
  }

  # K3s flannel
  ingress_security_rules {
    protocol = "17"
    source   = "10.0.0.0/16"
    udp_options {
      min = 8472
      max = 8472
    }
    description = "K3s flannel VXLAN"
  }

  # K3s metrics
  ingress_security_rules {
    protocol = "6"
    source   = "10.0.0.0/16"
    tcp_options {
      min = 10254
      max = 10254
    }
    description = "K3s metrics"
  }

  freeform_tags = {
    "Project" = "k3s-code-server"
  }
}