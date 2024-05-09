terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

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

# This is required for resource modules
resource "azurerm_resource_group" "rg" {
  location = local.azure_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

module "vnet" {
  source                        = "Azure/avm-res-network-virtualnetwork/azurerm"
  version                       = ">= 0.1.4"
  enable_telemetry              = var.enable_telemetry
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  name                          = module.naming.virtual_network.name_unique
  virtual_network_address_space = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["10.1.0.0/26"]
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = module.vnet.vnet_resource.name
}

resource "azurerm_public_ip" "pip" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.rg.location
  name                = "pip"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_ip_group" "ipgroup_1" {
  location            = azurerm_resource_group.rg.location
  name                = "ipgroup1"
  resource_group_name = azurerm_resource_group.rg.name
  cidrs               = ["192.168.0.1", "172.16.240.0/20", "10.48.0.0/12"]
}

resource "azurerm_ip_group" "ipgroup_2" {
  location            = azurerm_resource_group.rg.location
  name                = "ipgroup2"
  resource_group_name = azurerm_resource_group.rg.name
  cidrs               = ["10.100.10.0/24", "192.100.10.4", "10.150.20.20"]
}

# This is the module call
module "firewall" {
  source              = "Azure/avm-res-network-azurefirewall/azurerm"
  version             = ">= 0.1.3"
  name                = module.naming.firewall.name
  enable_telemetry    = var.enable_telemetry
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  firewall_sku_tier   = "Standard"
  firewall_sku_name   = "AZFW_VNet"
  firewall_zones      = ["1", "2", "3"]
  firewall_ip_configuration = [
    {
      name                 = "ipconfig1"
      subnet_id            = azurerm_subnet.subnet.id
      public_ip_address_id = azurerm_public_ip.pip.id
    }
  ]
  firewall_policy_id = module.firewall_policy.resource.id
}

module "firewall_policy" {
  source              = "../.."
  enable_telemetry    = var.enable_telemetry
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = module.naming.firewall_policy.name
}

module "rule_collection_group" {
  source                                                   = "../../modules/rule_collection_groups"
  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policy.resource.id
  firewall_policy_rule_collection_group_name               = "IPGroupRCG"
  firewall_policy_rule_collection_group_priority           = 400
  firewall_policy_rule_collection_group_network_rule_collection = [
    {
      action   = "Allow"
      name     = "NetworkRuleCollection"
      priority = 101
      rule = [
        {
          name                  = "OutboundToIPGroups"
          destination_ports     = ["443"]
          destination_ip_groups = [azurerm_ip_group.ipgroup_1.id]
          source_ip_groups      = [azurerm_ip_group.ipgroup_2.id]
          protocols             = ["TCP"]
        }
      ]
    }
  ]
  firewall_policy_rule_collection_group_application_rule_collection = [
    {
      action   = "Allow"
      name     = "ApplicationRuleCollection"
      priority = 201
      rule = [
        {
          name              = "AllowMicrosoft"
          destination_fqdns = ["*.microsoft.com"]
          source_ip_groups  = [azurerm_ip_group.ipgroup_2.id]
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
}