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

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
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

# Creating a default Azure Firewall Policy that will be the Parent Policy
resource "azurerm_firewall_policy" "parent_firewall_policy" {
  name                = "parent-firewall-policy"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

# This is the module call
module "firewall_policy" {
  source = "../.."
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  enable_telemetry    = var.enable_telemetry
  fw_policy_name      = "firewall-policy"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Standard"
  proxy_enabled       = false
  base_policy_id      = azurerm_firewall_policy.parent_firewall_policy.id

  threat_intel_mode = "Alert"
  rule_collection_group = {
    name               = "rule-collection-group"
    priority           = 300
    firewall_policy_id = module.firewall_policy.firewall_policy_id
  }
  app_rule_collection_name     = "app-rule-collection"
  app_rule_collection_priority = 400
  app_rule_collection_action   = "Allow"
  app_rule = {
    source_address = [ "*" ]
    destination_fqdns = [ "*.microsoft.com" ]
    protocols = {
      type = "Https"
      port = 443
    }
  }
  net_rule_collection_name     = "net-rule-collection"
  net_rule_collection_priority = 500
  net_rule_collection_action   = "Allow"
  net_rule = {
    protocols         = "TCP"
    destination_ports = ["443"]
  }
  nat_rule_collection_name     = "nat-rule-collection"
  nat_rule_collection_priority = 600
  nat_rule_collection_action   = "Dnat"
  nat_rule = {
    protocols       = ["TCP", "UDP"]
    translated_port = "8080"
  }
}