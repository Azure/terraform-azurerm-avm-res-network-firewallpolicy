terraform {
  # Raised from `>= 1.3.0` by the AzAPI migration to match the module under
  # test, which needs `>= 1.9`.
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azapi" {}

# NOTE: The azurerm provider block is required only when upgrading from a previous version of the module that used the azurerm provider. It can be removed in new implementations of the module or after upgrading.
# provider "azurerm" {
#   features {}
# }

data "azapi_client_config" "current" {}

# This picks a random region from the list of regions.
resource "random_integer" "region_index" {
  max = length(local.azure_regions) - 1
  min = 0
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This is required for resource modules.
#
# Created with `azapi_resource` rather than `azurerm_resource_group`: an example
# for an AzAPI module must not reintroduce the provider the module just dropped,
# or it stops demonstrating that the module works without it.
resource "azapi_resource" "rg" {
  location  = local.azure_regions[random_integer.region_index.result]
  name      = module.naming.resource_group.name_unique
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  body = {
    properties = {}
  }
}

# This is the module call
module "firewall_policy" {
  source = "../.."

  location = azapi_resource.rg.location
  name     = module.naming.firewall_policy.name_unique
  # source             = "Azure/avm-res-network-firewallpolicy/azurerm"
  enable_telemetry = var.enable_telemetry
  parent_id        = azapi_resource.rg.id
}
