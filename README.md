<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-network=firewallpolicy

This is the module to create an Azure Firewall Policy

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.71.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (>= 3.5.0)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (3.84.0)

- <a name="provider_random"></a> [random](#provider\_random) (3.6.0)

## Resources

The following resources are used by this module:

- [azurerm_firewall_policy.firewall_policy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy) (resource)
- [azurerm_firewall_policy_rule_collection_group.firewall_policy_collection_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [random_id.telem](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_fw_policy_name"></a> [fw\_policy\_name](#input\_fw\_policy\_name)

Description: The name of the Azure Firewall Policy.

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: The Azure region where the resources will be deployed.

Type: `string`

### <a name="input_proxy_enabled"></a> [proxy\_enabled](#input\_proxy\_enabled)

Description: This variable controls whether or not telemetry is enabled for the module.

Type: `bool`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_sku"></a> [sku](#input\_sku)

Description: The Azure Firewall Policy SKU.

Type: `string`

### <a name="input_threat_intel_mode"></a> [threat\_intel\_mode](#input\_threat\_intel\_mode)

Description: The threat intelligence mode for the Azure Firewall Policy.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_app_rule"></a> [app\_rule](#input\_app\_rule)

Description:   The map of Application Rules to use for the Azure Firewall Policy  
  Each object in the list must contain the following attributes:
  - `description`: (Optional) The description of the app rule
  - `protocols`: (Required) The protocols to use for the app rule
  - `type`: (Required) The type of protocol to use for the app rule
  - `port`: (Required) The port to use for the app rule
  - `source_address`: (Optional) The source address to use for the app rule
  - `source_ip_groups`: (Optional) The source ip groups to use for the app rule. Only use if your not using source\_address.
  - `destination_address`: (Optional) The destination address to use for the app rule
  - `destination_urls`: (Optional) The destination urls to use for the app rule
  - `destination_fqdns`: (Optional) The destination fqdns to use for the app rule
  - `destination_fqdns_tags`: (Optional) The destination fqdns tags to use for the app rule
  - `terminate_tls`: (Optional) The terminate tls to use for the app rule
  - `web_categories`: (Optional) The web categories to use for the app rule. Need Premium SKU for Firewall Policy

  Example Input:
  ```terraform
  # Allow Windows Update
  rule {
    name = "AllowWindowsUpdate"
    description = "Allow Windows Update to Virtual Machines"
    protocols = {
      type = "Https"
      port = 443
    }
    source_address = ["*"]
    destination_fqdns_tags = ["WindowsUpdate"]
  }
```

Type:

```hcl
map(object({
    description = optional(string)
    protocols = optional(list(object({
      type = optional(string)
      port = optional(number)
    })))
    source_addresses       = optional(list(string))
    source_ip_groups       = optional(list(string))
    destination_address    = optional(list(string))
    destination_urls       = optional(list(string))
    destination_fqdns      = optional(list(string))
    destination_fqdns_tags = optional(list(string))
    terminate_tls          = optional(bool)
    web_categories         = optional(list(string))
  }))
```

Default: `{}`

### <a name="input_app_rule_collection_action"></a> [app\_rule\_collection\_action](#input\_app\_rule\_collection\_action)

Description: value of the action for the Azure Firewall Policy Application Rule Collection.

Type: `string`

Default: `null`

### <a name="input_app_rule_collection_name"></a> [app\_rule\_collection\_name](#input\_app\_rule\_collection\_name)

Description: The name of the Azure Firewall Policy Application Rule Collection.

Type: `string`

Default: `null`

### <a name="input_app_rule_collection_priority"></a> [app\_rule\_collection\_priority](#input\_app\_rule\_collection\_priority)

Description: The priority of the Azure Firewall Policy Application Rule Collection.

Type: `number`

Default: `null`

### <a name="input_base_policy_id"></a> [base\_policy\_id](#input\_base\_policy\_id)

Description: The Azure Firewall Policy Base Policy ID.

Type: `string`

Default: `null`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: n/a

Type:

```hcl
map(object({
    name                                     = optional(string, null)
    log_categories_and_groups                = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers)

Description:   The list of DNS servers to use for the Azure Firewall Policy.  
  This will not be needed if the DNS proxy enabled is set to False

Type: `list(string)`

Default: `null`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: The lock level to apply to the Firewall Policy. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.

Type:

```hcl
object({
    name = optional(string, null)
    kind = optional(string, "None")

  })
```

Default: `{}`

### <a name="input_nat_rule"></a> [nat\_rule](#input\_nat\_rule)

Description:   The map of NAT Rules to use for the Azure Firewall Policy  
  Each object in the list must contain the following attributes:
  - `description`: (Optional) The description of the nat rule
  - `protocols`: (Required) The protocols to use for the nat rule
  - `source_addresses`: (Optional) The source addresses to use for the nat rule
  - `source_ip_groups`: (Optional) The source ip groups to use for the nat rule. Only use if your not using source\_addresses.
  - `destination_addresses`: (Optional) The destination addresses to use for the nat rule
  - `destination_ports`: (Optional) The destination ports to use for the nat rule
  - `translated_address`: (Optional) The translated address to use for the nat rule. This is required if you are not using translated\_fqdn
  - `translated_fqdn`: (Optional) The translated fqdn to use for the nat rule. This is required if you are not using translated\_address
  - `translated_port`: (Optional) The translated port to use for the nat rule

  Example Input:
  ```terraform
  rule {
      name                = "rdp"
      protocols           = ["TCP"]
      translated_address  = "10.10.1.4"
      translated_port     = "3389"
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.firewall_public_ip.ip_address
      destination_ports   = ["3389"]
    }

```

Type:

```hcl
map(object({
    description         = optional(string, null)
    protocols           = list(string)
    source_addresses    = optional(list(string))
    source_ip_groups    = optional(list(string))
    destination_address = optional(list(string))
    destination_ports   = optional(list(number))
    translated_address  = optional(string, null)
    translated_fqdn     = optional(string, null)
    translated_port     = number
  }))
```

Default: `{}`

### <a name="input_nat_rule_collection_action"></a> [nat\_rule\_collection\_action](#input\_nat\_rule\_collection\_action)

Description: value of the action for the Azure Firewall Policy NAT Rule Collection.

Type: `string`

Default: `null`

### <a name="input_nat_rule_collection_name"></a> [nat\_rule\_collection\_name](#input\_nat\_rule\_collection\_name)

Description: The name of the Azure Firewall Policy NAT Rule Collection.

Type: `string`

Default: `null`

### <a name="input_nat_rule_collection_priority"></a> [nat\_rule\_collection\_priority](#input\_nat\_rule\_collection\_priority)

Description: The priority of the Azure Firewall Policy NAT Rule Collection.

Type: `number`

Default: `null`

### <a name="input_net_rule"></a> [net\_rule](#input\_net\_rule)

Description:   
  The map of Network Rules to use for the Azure Firewall Policy  
  Each object in the list must contain the following attributes:

  - `description`: (Optional) The description of the net rule
  - `protocols`: (Required) The protocols to use for the net rule
  - `destination_ports`: (Required) The destination ports to use for the net rule
  - `source_addresses`: (Optional) The source address to use for the net rule
  - `source_ip_groups`: (Optional) The source ip groups to use for the net rule. Only use if your not using source\_address.
  - `destination_address`: (Optional) The destination address to use for the net rule
  - `destination_ip_groups`: (Optional) The destination ip groups to use for the net rule. Only use if your not using destination\_address.
  - `destination_fqdns`: (Optional) The destination fqdns to use for the net rule

  Example Input:
  ```terraform
  # Allow RDP to Virtual Machines
  rule {
    name = "AllowRDP"
    description = "Allow RDP to Virtual Machines"
    protocols = "TCP"
    destination_ports = [3389]
    source_addresses = ["*"]
    destination_address = ["*"]
  }
```

Type:

```hcl
map(object({
    description           = optional(string, null)
    protocols             = optional(list(string))
    destination_ports     = optional(list(string))
    source_addresses      = optional(list(string), null)
    source_ip_groups      = optional(list(string), null)
    destination_addresses = optional(list(string), null)
    destination_ip_groups = optional(list(string), null)
    destination_fqdns     = optional(list(string), null)
  }))
```

Default: `{}`

### <a name="input_net_rule_collection_action"></a> [net\_rule\_collection\_action](#input\_net\_rule\_collection\_action)

Description: value of the action for the Azure Firewall Policy Network Rule Collection.

Type: `string`

Default: `null`

### <a name="input_net_rule_collection_name"></a> [net\_rule\_collection\_name](#input\_net\_rule\_collection\_name)

Description: The name of the Azure Firewall Policy Network Rule Collection.

Type: `string`

Default: `null`

### <a name="input_net_rule_collection_priority"></a> [net\_rule\_collection\_priority](#input\_net\_rule\_collection\_priority)

Description: n/a

Type: `number`

Default: `null`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: n/a

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, true)
    condition                              = optional(string, null)
    condition_version                      = optional(string, "2.0")
    delegated_managed_identity_resource_id = optional(string)
  }))
```

Default: `{}`

### <a name="input_rule_collection_group"></a> [rule\_collection\_group](#input\_rule\_collection\_group)

Description:   The map of Rule Collection Groups to use for the Azure Firewall Policy. Name and Priority are required atrributes for Rule Collection Group.  
  You can create multiple Rule Collection Groups for different rule types i.e. Network, Application, NAT or you can use one Rule Collection Group for all rule types.  

  Example Input:
  ```terraform
  rule_collection_group = {
    group1 = {
      name     = "DefaultRuleCollectionGroup"
      priority = 300
    }
  }
```

Type:

```hcl
map(object({
    name               = string
    priority           = number
    firewall_policy_id = string
  }))
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: The tags to associate with your network and subnets.

Type: `map(any)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_firewall_policy"></a> [firewall\_policy](#output\_firewall\_policy)

Description: The ID of the Firewall Policy.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->