# TFLint configuration for OpenTofu
# TFLint is compatible with OpenTofu as it uses the same HCL syntax

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = false
}

plugin "azurerm" {
  enabled = false
}

plugin "google" {
  enabled = false
}

# OCI provider configuration
# Using general Terraform/OpenTofu rules as they are compatible

rule "terraform_naming_convention" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}
