resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_id
  display_name   = "oci-arm-dev-vcn"
  cidr_block     = "10.0.0.0/16"
  dns_label      = "devenv"
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "oci-arm-dev-igw"
}

resource "oci_core_route_table" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "oci-arm-dev-rt"
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

resource "oci_core_security_list" "main" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "oci-arm-dev-seclist"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # SSH, HTTP, HTTPS, K3s API, Code-server
  dynamic "ingress_security_rules" {
    for_each = [22, 80, 443, 6443, 8080]
    content {
      protocol = "6"
      source   = "0.0.0.0/0"
      tcp_options {
        min = ingress_security_rules.value
        max = ingress_security_rules.value
      }
    }
  }

  # Internal K3s communication
  ingress_security_rules {
    protocol = "6"
    source   = "10.0.0.0/16"
    tcp_options {
      min = 10250
      max = 10250
    }
  }

  ingress_security_rules {
    protocol = "17"
    source   = "10.0.0.0/16"
    udp_options {
      min = 8472
      max = 8472
    }
  }
}

resource "oci_core_subnet" "main" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.main.id
  cidr_block        = "10.0.1.0/24"
  route_table_id    = oci_core_route_table.main.id
  security_list_ids = [oci_core_security_list.main.id]
  dns_label         = "devsubnet"
}
