terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}

data "azapi_client_config" "caller" {}

resource "terraform_data" "upstream" {
  input = var.upstream_input
}

module "fp" {
  source = "../../../.."

  location            = "eastus"
  name                = "firewall-policy-test"
  enable_telemetry    = false
  resource_group_name = "legacy-rg"

  depends_on = [terraform_data.upstream]
}

output "parent_id" {
  value = module.fp.resource.parent_id
}
