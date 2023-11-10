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
  enable_telemetry            = var.enable_telemetry
  fw_policy_name              = "firewall-policy"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = "Standard"
  proxy_enabled               = false
  dns_servers                 = [""]
  threat_intel_fqdn_allowlist = ["*microsoft.com"]
  threat_intel_ip_allowlist   = [""]
  threat_intel_mode           = "Alert"
  fw_policy_rcg_name          = "fw-policy-rcg"
  priority                    = 300
  application_rule_collection {
    name     = "app-rule-collection"
    priority = 300
    action   = "Allow"
    app_rule {
      name = "TelemetryService"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["*"]
      destination_fqdns = ["*.events.data.microsoft.com"]
    }
    app_rule {
      name = "Windows Update"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["*"]
      destination_fqdns = ["*.sfx.ms"]
    }
    app_rule {
      name = "UpdatesforOneDrive"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses      = ["*"]
      destination_fqdn_tags = ["WindowsUpdate"]
    }
    app_rule {
      name = "DigitcertCRL"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["*"]
      destination_fqdns = ["*.digicert.com"]
    }
    app_rule {
      name = "AzureDNSResolution"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["*"]
      destination_fqdns = ["*.azure-dns.com"]
    }
    app_rule {
      name = "AzureDNSresolution2"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["*"]
      destination_fqdns = ["*.azure-dns.net"]
    }
  }
  network_rule_collection {
    name     = "net-rule-collection"
    priority = 300
    action   = "Allow"
    net_rule {
      name                  = "Service Traffic"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["WindowsVirtualDesktop"]
      destination_ports     = ["443"]
    }
    net_rule {
      name                  = "Agent Traffic"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureMonitor"]
      destination_ports     = ["443"]
    }
    net_rule {
      name                  = "Azure Marketplace"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureFrontDoor.Frontend"]
      destination_ports     = ["443"]
    }
    net_rule {
      name                  = "Windows Activation"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["kms.core.windows.net"]
      destination_ports     = ["1688"]
    }
    net_rule {
      name                  = "Auth to Msft Online Services"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["login.microsoftonline.com	"]
      destination_ports     = ["443"]
    }

    net_rule {
      name                  = "Azure Windows Activation"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["azkms.core.windows.net"]
      destination_ports     = ["1688"]
    }
    net_rule {
      name                  = "Agent and SxS Stack Updates"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["mrsglobalsteus2prod.blob.core.windows.net"]
      destination_ports     = ["443"]
    }
    net_rule {
      name                  = "Azure Portal Support"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["wvdportalstorageblob.blob.core.windows.net"]
      destination_ports     = ["443"]
    }
    net_rule {
      name                  = "Azure Instance Metadata Service Endpoint"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["169.254.169.254"]
      destination_ports     = ["80"]
    }
    net_rule {
      name                  = "Session Host Health Monitoring"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["168.63.129.16"]
      destination_ports     = ["80"]
    }
    net_rule {
      name                  = "Cert CRL OneOCSP"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["oneocsp.microsoft.com"]
      destination_ports     = ["80"]
    }
    net_rule {
      name                  = "Cert CRL MicrosoftDotCom"
      protocols             = ["TCP"]
      source_addresses      = ["*"]
      destination_addresses = ["www.microsoft.com"]
      destination_ports     = ["80"]
    }
  }
}

