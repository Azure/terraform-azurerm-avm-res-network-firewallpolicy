<!-- BEGIN_TF_DOCS -->
# Deploy Firewall Policy with IP Groups

This deploys an Azure Firewall Policy with IP Groups in the rules

- Firewall
- Firewall Policy
- Rule Collection Groups
- Rule Collections
- Network and Application Rules
- IP Groups

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
resource "azurerm_resource_group" "rg" {
  location = local.azure_regions[random_integer.region_index.result]
  name     = module.naming.resource_group.name_unique
}

module "vnet" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = ">=0.2.0"
  enable_telemetry    = var.enable_telemetry
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  name                = module.naming.virtual_network.name_unique
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["10.1.0.0/26"]
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = module.vnet.resource.name
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

- [azurerm_ip_group.ipgroup_1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ip_group) (resource)
- [azurerm_ip_group.ipgroup_2](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ip_group) (resource)
- [azurerm_public_ip.pip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
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

### <a name="module_firewall"></a> [firewall](#module\_firewall)

Source: Azure/avm-res-network-azurefirewall/azurerm

Version: >= 0.1.3

### <a name="module_firewall_policy"></a> [firewall\_policy](#module\_firewall\_policy)

Source: ../..

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

### <a name="module_rule_collection_group"></a> [rule\_collection\_group](#module\_rule\_collection\_group)

Source: ../../modules/rule_collection_groups

Version:

### <a name="module_vnet"></a> [vnet](#module\_vnet)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: >=0.2.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->