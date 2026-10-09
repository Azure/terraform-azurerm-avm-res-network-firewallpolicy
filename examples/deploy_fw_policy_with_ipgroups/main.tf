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
# Every supporting resource below is AzAPI. The example previously built its
# dependencies with `azurerm_resource_group`, `azurerm_subnet`,
# `azurerm_public_ip` and `azurerm_ip_group`, and pulled in an AzureRM-based
# firewall module; an example for an AzAPI module must not reintroduce the
# provider the module just dropped, or it stops proving that the module works
# without it.
resource "azapi_resource" "rg" {
  location  = local.azure_regions[random_integer.region_index.result]
  name      = module.naming.resource_group.name_unique
  parent_id = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  type      = "Microsoft.Resources/resourceGroups@2025-04-01"
  body = {
    properties = {}
  }
}

# 0.22.2 is the first AzAPI-based release of the virtual network module. The
# subnet is created through its `subnets` input rather than as a separate
# resource, which is also how the module prefers subnets to be declared.
module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.22.2"

  location         = azapi_resource.rg.location
  parent_id        = azapi_resource.rg.id
  address_space    = ["10.1.0.0/16"]
  enable_telemetry = var.enable_telemetry
  name             = module.naming.virtual_network.name_unique
  subnets = {
    firewall = {
      name           = "AzureFirewallSubnet"
      address_prefix = "10.1.0.0/26"
    }
  }
}

resource "azapi_resource" "pip" {
  location  = azapi_resource.rg.location
  name      = "pip"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Network/publicIPAddresses@2025-07-01"
  body = {
    properties = {
      publicIPAllocationMethod = "Static"
    }
    sku = {
      name = "Standard"
    }
    zones = ["1", "2", "3"]
  }
}

# `cidrs` on `azurerm_ip_group` is `properties.ipAddresses` in ARM. The member
# takes both bare addresses and CIDR blocks, which is why the mixed list below
# is legal.
resource "azapi_resource" "ipgroup_1" {
  location  = azapi_resource.rg.location
  name      = "ipgroup1"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Network/ipGroups@2025-07-01"
  body = {
    properties = {
      ipAddresses = ["192.168.0.1", "172.16.240.0/20", "10.48.0.0/12"]
    }
  }
}

resource "azapi_resource" "ipgroup_2" {
  location  = azapi_resource.rg.location
  name      = "ipgroup2"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Network/ipGroups@2025-07-01"
  body = {
    properties = {
      ipAddresses = ["10.100.10.0/24", "192.100.10.4", "10.150.20.20"]
    }
  }
}

# The firewall exists only to give the policy something to attach to. It was
# `Azure/avm-res-network-azurefirewall/azurerm`, which at 0.4.0 is still an
# AzureRM module; a direct `azapi_resource` keeps this example free of the
# AzureRM provider. Swap it back for the AVM module once that module has been
# migrated.
resource "azapi_resource" "firewall" {
  location  = azapi_resource.rg.location
  name      = module.naming.firewall.name
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Network/azureFirewalls@2025-07-01"
  body = {
    properties = {
      firewallPolicy = {
        id = module.firewall_policy.resource_id
      }
      ipConfigurations = [
        {
          name = "ipconfig1"
          properties = {
            publicIPAddress = {
              id = azapi_resource.pip.id
            }
            subnet = {
              id = module.vnet.subnets["firewall"].resource_id
            }
          }
        }
      ]
      sku = {
        name = "AZFW_VNet"
        tier = "Standard"
      }
    }
    zones = ["1", "2", "3"]
  }
}

# This is the module call
module "firewall_policy" {
  source = "../.."

  location         = azapi_resource.rg.location
  name             = module.naming.firewall_policy.name
  enable_telemetry = var.enable_telemetry
  parent_id        = azapi_resource.rg.id
}

module "rule_collection_group" {
  source = "../../modules/rule_collection_groups"

  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policy.resource_id
  firewall_policy_rule_collection_group_name               = "IPGroupRCG"
  firewall_policy_rule_collection_group_priority           = 400
  firewall_policy_rule_collection_group_application_rule_collection = [
    {
      action   = "Allow"
      name     = "ApplicationRuleCollection"
      priority = 201
      rule = [
        {
          name              = "AllowMicrosoft"
          destination_fqdns = ["*.microsoft.com"]
          source_ip_groups  = [azapi_resource.ipgroup_2.id]
          protocols = [
            {
              port = 443
              type = "Https"
            }
          ]
        }
      ]
    }
  ]
  firewall_policy_rule_collection_group_network_rule_collection = [
    {
      action   = "Allow"
      name     = "NetworkRuleCollection"
      priority = 101
      rule = [
        {
          name                  = "OutboundToIPGroups"
          destination_ports     = ["443"]
          destination_ip_groups = [azapi_resource.ipgroup_1.id]
          source_ip_groups      = [azapi_resource.ipgroup_2.id]
          protocols             = ["TCP"]
        }
      ]
    }
  ]
}
