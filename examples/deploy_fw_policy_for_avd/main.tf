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
resource "azurerm_resource_group" "this" {
  location = local.azure_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

# This is the module call
module "firewall_policy" {
  source = "../.."
  # source             = "Azure/avm-res-network-firewallpolicy/azurerm"
  enable_telemetry    = var.enable_telemetry
  name                = module.naming.firewall_policy.name_unique
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  firewall_policy_dns = {
    proxy_enabled = true
  }
}

module "avd_core_rule_collection_group" {
  source = "../../modules/rule_collection_groups"
  # source             = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policy.resource.id
  firewall_policy_rule_collection_group_name               = "NetworkRuleCollectionGroup"
  firewall_policy_rule_collection_group_priority           = 1000
  firewall_policy_rule_collection_group_network_rule_collection = [{
    action   = "Allow"
    name     = "AVDCoreNetworkRules"
    priority = 500
    rule = [
      {
        name              = "Login to Microsoft"
        source_addresses  = ["10.100.0.0/24"]
        destination_fqdns = ["login.microsoftonline.com"]
        protocols         = ["TCP"]
        destination_ports = ["443"]
      },
      {
        name                  = "AVD"
        source_addresses      = ["10.100.0.0/24"]
        destination_addresses = ["WindowsVirtualDesktop", "AzureFrontDoor.Frontend", "AzureMonitor"]
        protocols             = ["TCP"]
        destination_ports     = ["443"]
      },
      {
        name              = "GCS"
        source_addresses  = ["10.100.0.0/24"]
        destination_fqdns = ["gcs.prod.monitoring.core.windows.net"]
        protocols         = ["TCP"]
        destination_ports = ["443"]
      },
      {
        name                  = "DNS"
        source_addresses      = ["10.100.0.0/24"]
        destination_addresses = ["AzureDNS"]
        protocols             = ["TCP", "UDP"]
        destination_ports     = ["53"]
      },
      {
        name              = "azkms"
        source_addresses  = ["10.100.0.0/24"]
        destination_fqdns = ["azkms.core.windows.net"]
        protocols         = ["TCP"]
        destination_ports = ["1688"]
      },
      {
        name              = "KMS"
        source_addresses  = ["10.100.0.0/24"]
        destination_fqdns = ["kms.core.windows.net"]
        protocols         = ["TCP"]
        destination_ports = ["1688"]
      },
      {
        name              = "mrglobalblob"
        source_addresses  = ["10.100.0.0/24"]
        destination_fqdns = ["mrsglobalsteus2prod.blob.core.windows.net"]
        protocols         = ["TCP"]
        destination_ports = ["443"]
      },
      {
        name              = "wvdportalstorageblob"
        source_addresses  = ["10.100.0.0/24"]
        destination_fqdns = ["wvdportalstorageblob.blob.core.windows.net"]
        protocols         = ["TCP"]
        destination_ports = ["443"]
      },
      {
        name              = "oneocsp"
        source_addresses  = ["10.100.0.0/24"]
        destination_fqdns = ["oneocsp.microsoft.com"]
        protocols         = ["TCP"]
        destination_ports = ["443"]
      },
      {
        name              = "microsoft.com"
        source_addresses  = ["10.100.0.0/24"]
        destination_fqdns = ["www.microsoft.com"]
        protocols         = ["TCP"]
        destination_ports = ["443"]
      },
    ]
    }
  ]
}


module "avd_optional_rule_collection_group" {
  source = "../../modules/rule_collection_groups"
  # source             = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policy.resource.id
  firewall_policy_rule_collection_group_name               = "AVDOptionalRuleCollectionGroup"
  firewall_policy_rule_collection_group_priority           = 1050
  firewall_policy_rule_collection_group_network_rule_collection = [{
    action   = "Allow"
    name     = "AVDOptionalNetworkRules"
    priority = 500
    rule = [
      {
        name              = "time"
        source_addresses  = ["10.0.0.0/24"]
        destination_fqdns = ["time.windows.com"]
        protocols         = ["UDP"]
        destination_ports = ["123"]
      },
      {
        name              = "login windows.net"
        source_addresses  = ["10.0.0.0/24"]
        destination_fqdns = ["login.windows.net"]
        protocols         = ["TCP"]
        destination_ports = ["443"]
      },
      {
        name              = "msftconnecttest"
        source_addresses  = ["10.0.0.0/24"]
        destination_fqdns = ["www.msftconnecttest.com"]
        protocols         = ["TCP"]
        destination_ports = ["443"]
      },
    ]
  }
  ]

  firewall_policy_rule_collection_group_application_rule_collection = [{
    action   = "Allow"
    name     = "AVDOptionalApplicationRules"
    priority = 600
    rule = [
      {
        name                  = "Windows"
        source_addresses      = ["10.0.0.0/24"]
        destination_fqdn_tags = ["WindowsUpdate", "WindowsDiagnostics", "MicrosoftActiveProtectionService"]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name              = "Events"
        source_addresses  = ["10.0.0.0/24"]
        destination_fqdns = ["*.events.data.microsoft.com"]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name              = "sfx"
        source_addresses  = ["10.0.0.0/24"]
        destination_fqdns = ["*.sfx.ms"]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name              = "digicert"
        source_addresses  = ["10.0.0.0/24"]
        destination_fqdns = ["*.digicert.com"]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
      {
        name              = "Azure DNS"
        source_addresses  = ["10.0.0.0/24"]
        destination_fqdns = ["*.azure-dns.com", "*.azure-dns.net"]
        protocols = [
          {
            port = 443
            type = "Https"
          }
        ]
      },
    ]
    }
  ]
}

module "m365rulecollectiongroup" {
  source = "../../modules/rule_collection_groups"
  # source             = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policy.resource.id
  firewall_policy_rule_collection_group_name               = "M365RuleCollectionGroup"
  firewall_policy_rule_collection_group_priority           = 2000
  firewall_policy_rule_collection_group_network_rule_collection = [{
    action   = "Allow"
    name     = "M365NetworkRules"
    priority = 500
    rule = [
      {
        name                  = "M365"
        source_addresses      = ["10.0.0.0/24"]
        destination_addresses = ["Office365.Common.Allow.Required"]
        protocols             = ["TCP"]
        destination_ports     = ["443"]
      }
    ]
    }
  ]
}

module "internetrulecollectiongroup" {
  source = "../../modules/rule_collection_groups"
  # source             = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policy.resource.id
  firewall_policy_rule_collection_group_name               = "InternetRuleCollectionGroup"
  firewall_policy_rule_collection_group_priority           = 3000
  firewall_policy_rule_collection_group_network_rule_collection = [{
    action   = "Allow"
    name     = "InternetNetworkRules"
    priority = 500
    rule = [
      {
        name                  = "Internet"
        source_addresses      = ["10.0.0.0/24"]
        destination_addresses = ["*"]
        protocols             = ["TCP"]
        destination_ports     = ["443", "80"]
      }
    ]
    }
  ]
}