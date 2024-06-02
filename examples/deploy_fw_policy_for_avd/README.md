<!-- BEGIN_TF_DOCS -->
# Deploy Firewall Policy for Azure Virtual Desktop

This example deploys an Azure Firewall Policy with the required rules needed for Azure Virtual Desktop.

- Firewall Policy
- Rule Collection Group
- Rule Collection
- Network and Application Rules

```hcl
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0, < 4.0.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.7.0, < 4.0.0)

- <a name="provider_random"></a> [random](#provider\_random) (>= 3.5.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_avd_core_rule_collection_group"></a> [avd\_core\_rule\_collection\_group](#module\_avd\_core\_rule\_collection\_group)

Source: ../../modules/rule_collection_groups

Version:

### <a name="module_avd_optional_rule_collection_group"></a> [avd\_optional\_rule\_collection\_group](#module\_avd\_optional\_rule\_collection\_group)

Source: ../../modules/rule_collection_groups

Version:

### <a name="module_firewall_policy"></a> [firewall\_policy](#module\_firewall\_policy)

Source: ../..

Version:

### <a name="module_internetrulecollectiongroup"></a> [internetrulecollectiongroup](#module\_internetrulecollectiongroup)

Source: ../../modules/rule_collection_groups

Version:

### <a name="module_m365rulecollectiongroup"></a> [m365rulecollectiongroup](#module\_m365rulecollectiongroup)

Source: ../../modules/rule_collection_groups

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->