terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# This picks a random region from the list of regions.
resource "random_integer" "region_index" {
  min = 0
  max = length(local.azure_regions) - 1
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group.name_unique
  location = local.azure_regions[random_integer.region_index.result]
}

# This is the module call
module "firewall_policy" {
  source = "../.."
  # source             = "Azure/avm-res-network-firewallpolicy/azurerm"
  enable_telemetry    = var.enable_telemetry
  fw_policy_name      = "firewall-policy"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Standard"
  proxy_enabled       = false
  threat_intel_mode   = "Alert"
  rule_collection_group = {
    group1 = {
      name     = "rule-collection-group"
      priority = 300
  } }

  /*
  app_rule_collection_name     = "app-rule-collection"
  app_rule_collection_priority = 400
  app_rule_collection_action   = "Allow"
  app_rule = {
    rule1 = {
      source_addresses  = ["*"]
      destination_fqdns = ["*.microsoft.com"]
      protocols = [
        {
          type = "Http"
          port = 80
        }
      ]
    }
  }

  net_rule_collection_name     = "net-rule-collection"
  net_rule_collection_priority = 500
  net_rule_collection_action   = "Allow"
  net_rule = {
    rule1 = {
      name              = "net-rule"
      protocols         = ["TCP"]
      destination_ports = 80
    }
  }
    nat_rule_collection_name     = "nat-rule-collection"
  nat_rule_collection_priority = 600
  nat_rule_collection_action   = "Dnat"
  nat_rule = {
    rule1 = {
      protocols          = ["TCP", "UDP"]
      translated_address = "192.168.10.0"
      translated_port    = 8080
    }
  }
*/
}