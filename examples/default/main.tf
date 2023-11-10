terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0, < 4.0.0"
    }
  }
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

# This is the module call
module "firewall_policy" {
  source = "Azure/avm-res-network-firewallpolicy/azurerm"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  enable_telemetry             = var.enable_telemetry
  fw_policy_name               = "firewall-policy"
  resource_group_name          = azurerm_resource_group.this.name
  location                     = azurerm_resource_group.this.location
  sku                          = "Standard"
  proxy_enabled                = false
  dns_servers                  = [""]
  threat_intel_fqdn_allowlist  = ["*microsoft.com"]
  threat_intel_ip_allowlist    = [""]
  threat_intel_mode            = "Alert"
  fw_policy_rcg_name           = "fw-policy-rcg"
  priority                     = 300
  app_rule_collection_name     = "app-rule-collection"
  app_rule_collection_priority = 400
  app_rule_collection_action   = "Allow"
  app_rule = {
    description = "HTTPS rule"
    protocols = {
      type = "Https"
      port = "443"
    }
    source_addresses  = ["*"]
    destination_fqdns = ["*.microsoft.com"]
    terminate_tls     = false
  }
  net_rule_collection_name     = "net-rule-collection"
  net_rule_collection_priority = 500
  net_rule_collection_action   = "Allow"
  net_rule = {
    description           = "Allow RDP"
    protocols             = ["TCP"]
    source_addresses      = ["*"]
    destination_addresses = ["132.87.101.123"]
    destination_ports     = ["3389"]
  }
  nat_rule_collection_name     = "nat-rule-collection"
  nat_rule_collection_priority = 600
  nat_rule_collection_action   = "Dnat"
  nat_rule = {
    description           = "DNAT rule"
    protocols             = ["TCP"]
    source_addresses      = ["*"]
    translated_address    = ["10.10.1.4"]
    translated_port       = "3389"
    destination_addresses = ["124.12.44.100"]
    destination_ports     = ["3389"]
  }
  tags = {
    environment = "dev"
  }
}
