<!-- BEGIN_TF_DOCS -->
# Default example

This deploys a parent policy and it will deploy a child policy. The child policy will inherit the rules from the parent policy.

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

- [azurerm_firewall_policy.parent_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy) (resource)
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

### <a name="module_firewall_policy"></a> [firewall\_policy](#module\_firewall\_policy)

Source: ../..

Version:

### <a name="module_log_analytics_workspace"></a> [log\_analytics\_workspace](#module\_log\_analytics\_workspace)

Source: Azure/avm-res-operationalinsights-workspace/azurerm

Version: 0.1.2

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

### <a name="module_rule_collection_group"></a> [rule\_collection\_group](#module\_rule\_collection\_group)

Source: ../../modules/rule_collection_groups

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->