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
  min = 0
  max = length(local.azure_regions) - 1
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

module "log_analytics_workspace" {
  source              = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version             = "0.1.2"
  name                = module.naming.log_analytics_workspace.name_unique
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  name     = module.naming.resource_group.name_unique
  location = local.azure_regions[random_integer.region_index.result]
}

resource "azurerm_firewall_policy" "parent_policy" {
  name                     = "fw-policy-parent"
  location                 = azurerm_resource_group.this.location
  resource_group_name      = azurerm_resource_group.this.name
  sku                      = "Standard"
  threat_intelligence_mode = "Alert"
  dns {
    proxy_enabled = true
  }
  insights {
    default_log_analytics_workspace_id = module.log_analytics_workspace.workspace_id.id
    enabled                            = true
  }
}

module "rule_collection_group" {
  source = "../../modules/rule_collection_groups"
  # source = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  firewall_policy_rule_collection_group_firewall_policy_id = azurerm_firewall_policy.parent_policy.id
  firewall_policy_rule_collection_group_name               = "rcg-parent"
  firewall_policy_rule_collection_group_priority           = 200
  firewall_policy_rule_collection_group_network_rule_collection = [
    {
      action   = "Allow"
      name     = "netrule-collection-allow"
      priority = 200
      rule = [
        {
          name              = "allow-msft"
          description       = "Allow all traffic to Microsoft"
          source_addresses  = ["*"]
          destination_ports = ["*"]
          protocols         = ["TCP", "UDP"]
          destination_fqdns = ["microsoft.com"]
        }
      ]
    },
    {
      action   = "Deny"
      name     = "netrule-collection-deny"
      priority = 300
      rule = [
        {
          name              = "deny-google"
          description       = "Deny all traffic to Google"
          source_addresses  = ["*"]
          destination_ports = ["*"]
          protocols         = ["TCP", "UDP"]
          destination_fqdns = ["google.com"]
        }
      ]
    }
  ]
}

# This is the module call
module "firewall_policy" {
  source = "../.."
  # source             = "Azure/avm-res-network-firewallpolicy/azurerm"
  enable_telemetry               = var.enable_telemetry
  name                           = module.naming.firewall_policy.name_unique
  location                       = azurerm_resource_group.this.location
  resource_group_name            = azurerm_resource_group.this.name
  firewall_policy_base_policy_id = azurerm_firewall_policy.parent_policy.id
}
