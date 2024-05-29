<!-- BEGIN_TF_DOCS -->
# Azure Firewall Policy Rule Collection Group

This is the sub-module to create Rule Collection Groups in Azure Firewall Policy

## Features

This module supports:

- Creates Rule Collection Groups
- Creates Rule Collections
- Creates Network Rules, Application Rules, and NAT Rules

"Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>"

```hcl
resource "azurerm_firewall_policy_rule_collection_group" "this" {
  firewall_policy_id = var.firewall_policy_rule_collection_group_firewall_policy_id
  name               = var.firewall_policy_rule_collection_group_name
  priority           = var.firewall_policy_rule_collection_group_priority

  dynamic "application_rule_collection" {
    for_each = var.firewall_policy_rule_collection_group_application_rule_collection == null ? [] : var.firewall_policy_rule_collection_group_application_rule_collection
    content {
      action   = application_rule_collection.value.action
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority

      dynamic "rule" {
        for_each = application_rule_collection.value.rule
        content {
          name                  = rule.value.name
          description           = rule.value.description
          destination_addresses = rule.value.destination_addresses
          destination_fqdn_tags = rule.value.destination_fqdn_tags
          destination_fqdns     = rule.value.destination_fqdns
          destination_urls      = rule.value.destination_urls
          source_addresses      = rule.value.source_addresses
          source_ip_groups      = rule.value.source_ip_groups
          terminate_tls         = rule.value.terminate_tls
          web_categories        = rule.value.web_categories

          dynamic "http_headers" {
            for_each = rule.value.http_headers == null ? [] : rule.value.http_headers
            content {
              name  = http_headers.value.name
              value = http_headers.value.value
            }
          }
          dynamic "protocols" {
            for_each = rule.value.protocols == null ? [] : rule.value.protocols
            content {
              port = protocols.value.port
              type = protocols.value.type
            }
          }
        }
      }
    }
  }
  dynamic "nat_rule_collection" {
    for_each = var.firewall_policy_rule_collection_group_nat_rule_collection == null ? [] : var.firewall_policy_rule_collection_group_nat_rule_collection
    content {
      action   = nat_rule_collection.value.action
      name     = nat_rule_collection.value.name
      priority = nat_rule_collection.value.priority

      dynamic "rule" {
        for_each = nat_rule_collection.value.rule
        content {
          name                = rule.value.name
          protocols           = rule.value.protocols
          translated_port     = rule.value.translated_port
          destination_address = rule.value.destination_address
          destination_ports   = rule.value.destination_ports
          source_addresses    = rule.value.source_addresses
          source_ip_groups    = rule.value.source_ip_groups
          translated_address  = rule.value.translated_address
          translated_fqdn     = rule.value.translated_fqdn
        }
      }
    }
  }
  dynamic "network_rule_collection" {
    for_each = var.firewall_policy_rule_collection_group_network_rule_collection == null ? [] : var.firewall_policy_rule_collection_group_network_rule_collection
    content {
      action   = network_rule_collection.value.action
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority

      dynamic "rule" {
        for_each = network_rule_collection.value.rule
        content {
          destination_ports     = rule.value.destination_ports
          name                  = rule.value.name
          protocols             = rule.value.protocols
          destination_addresses = rule.value.destination_addresses
          destination_fqdns     = rule.value.destination_fqdns
          destination_ip_groups = rule.value.destination_ip_groups
          source_addresses      = rule.value.source_addresses
          source_ip_groups      = rule.value.source_ip_groups
        }
      }
    }
  }
  dynamic "timeouts" {
    for_each = var.firewall_policy_rule_collection_group_timeouts == null ? [] : [var.firewall_policy_rule_collection_group_timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.5.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.71)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.71)

## Resources

The following resources are used by this module:

- [azurerm_firewall_policy_rule_collection_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy_rule_collection_group) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_firewall_policy_rule_collection_group_firewall_policy_id"></a> [firewall\_policy\_rule\_collection\_group\_firewall\_policy\_id](#input\_firewall\_policy\_rule\_collection\_group\_firewall\_policy\_id)

Description: (Required) The ID of the Firewall Policy where the Firewall Policy Rule Collection Group should exist. Changing this forces a new Firewall Policy Rule Collection Group to be created.

Type: `string`

### <a name="input_firewall_policy_rule_collection_group_name"></a> [firewall\_policy\_rule\_collection\_group\_name](#input\_firewall\_policy\_rule\_collection\_group\_name)

Description: (Required) The name which should be used for this Firewall Policy Rule Collection Group. Changing this forces a new Firewall Policy Rule Collection Group to be created.

Type: `string`

### <a name="input_firewall_policy_rule_collection_group_priority"></a> [firewall\_policy\_rule\_collection\_group\_priority](#input\_firewall\_policy\_rule\_collection\_group\_priority)

Description: (Required) The priority of the Firewall Policy Rule Collection Group. The range is 100-65000.

Type: `number`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description:   A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
  - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
  - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
  - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
  - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
  - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
  - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
  - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
  - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
  - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.

Type:

```hcl
map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
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

### <a name="input_firewall_policy_rule_collection_group_application_rule_collection"></a> [firewall\_policy\_rule\_collection\_group\_application\_rule\_collection](#input\_firewall\_policy\_rule\_collection\_group\_application\_rule\_collection)

Description: - `action` - (Required) The action to take for the application rules in this collection. Possible values are `Allow` and `Deny`.
- `name` - (Required) The name which should be used for this application rule collection.
- `priority` - (Required) The priority of the application rule collection. The range is `100`

---
`rule` block supports the following:
- `description` -
- `destination_addresses` -
- `destination_fqdn_tags` -
- `destination_fqdns` -
- `destination_urls` -
- `name` - (Required) The name which should be used for this Firewall Policy Rule Collection Group. Changing this forces a new Firewall Policy Rule Collection Group to be created.
- `source_addresses` -
- `source_ip_groups` -
- `terminate_tls` -
- `web_categories` -

---
`http_headers` block supports the following:
- `name` - (Required) Specifies the name of the header.
- `value` - (Required) Specifies the value of the value.

---
`protocols` block supports the following:
- `port` - (Required) Port number of the protocol. Range is 0-64000.
- `type` - (Required) Protocol type. Possible values are `Http` and `Https`.

Type:

```hcl
list(object({
    action   = string
    name     = string
    priority = number
    rule = list(object({
      description           = optional(string)
      destination_addresses = optional(list(string))
      destination_fqdn_tags = optional(list(string))
      destination_fqdns     = optional(list(string))
      destination_urls      = optional(list(string))
      name                  = string
      source_addresses      = optional(list(string))
      source_ip_groups      = optional(list(string))
      terminate_tls         = optional(bool)
      web_categories        = optional(list(string))
      http_headers = optional(list(object({
        name  = string
        value = string
      })))
      protocols = optional(list(object({
        port = number
        type = string
      })))
    }))
  }))
```

Default: `null`

### <a name="input_firewall_policy_rule_collection_group_nat_rule_collection"></a> [firewall\_policy\_rule\_collection\_group\_nat\_rule\_collection](#input\_firewall\_policy\_rule\_collection\_group\_nat\_rule\_collection)

Description: - `action` - (Required) The action to take for the NAT rules in this collection. Currently, the only possible value is `Dnat`.
- `name` - (Required) The name which should be used for this NAT rule collection.
- `priority` - (Required) The priority of the NAT rule collection. The range is `100`

---
`rule` block supports the following:
- `description` -
- `destination_address` -
- `destination_ports` -
- `name` - (Required) The name which should be used for this Firewall Policy Rule Collection Group. Changing this forces a new Firewall Policy Rule Collection Group to be created.
- `protocols` -
- `source_addresses` -
- `source_ip_groups` -
- `translated_address` -
- `translated_fqdn` -
- `translated_port` -

Type:

```hcl
list(object({
    action   = string
    name     = string
    priority = number
    rule = list(object({
      description         = optional(string)
      destination_address = optional(string)
      destination_ports   = optional(list(string))
      name                = string
      protocols           = list(string)
      source_addresses    = optional(list(string))
      source_ip_groups    = optional(list(string))
      translated_address  = optional(string)
      translated_fqdn     = optional(string)
      translated_port     = number
    }))
  }))
```

Default: `null`

### <a name="input_firewall_policy_rule_collection_group_network_rule_collection"></a> [firewall\_policy\_rule\_collection\_group\_network\_rule\_collection](#input\_firewall\_policy\_rule\_collection\_group\_network\_rule\_collection)

Description: - `action` - (Required) The action to take for the network rules in this collection. Possible values are `Allow` and `Deny`.
- `name` - (Required) The name which should be used for this network rule collection.
- `priority` - (Required) The priority of the network rule collection. The range is `100`

---
`rule` block supports the following:
- `description` -
- `destination_addresses` -
- `destination_fqdns` -
- `destination_ip_groups` -
- `destination_ports` -
- `name` - (Required) The name which should be used for this Firewall Policy Rule Collection Group. Changing this forces a new Firewall Policy Rule Collection Group to be created.
- `protocols` -
- `source_addresses` -
- `source_ip_groups` -

Type:

```hcl
list(object({
    action   = string
    name     = string
    priority = number
    rule = list(object({
      description           = optional(string)
      destination_addresses = optional(list(string))
      destination_fqdns     = optional(list(string))
      destination_ip_groups = optional(list(string))
      destination_ports     = list(string)
      name                  = string
      protocols             = list(string)
      source_addresses      = optional(list(string))
      source_ip_groups      = optional(list(string))
    }))
  }))
```

Default: `null`

### <a name="input_firewall_policy_rule_collection_group_timeouts"></a> [firewall\_policy\_rule\_collection\_group\_timeouts](#input\_firewall\_policy\_rule\_collection\_group\_timeouts)

Description: - `create` - (Defaults to 30 minutes) Used when creating the Firewall Policy Rule Collection Group.
- `delete` - (Defaults to 30 minutes) Used when deleting the Firewall Policy Rule Collection Group.
- `read` - (Defaults to 5 minutes) Used when retrieving the Firewall Policy Rule Collection Group.
- `update` - (Defaults to 30 minutes) Used when updating the Firewall Policy Rule Collection Group.

Type:

```hcl
object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
```

Default: `null`

### <a name="input_lock"></a> [lock](#input\_lock)

Description:   Controls the Resource Lock configuration for this resource. The following properties can be specified:

  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description:   Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description:   A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) A mapping of tags to assign to the resource.

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: this is the resource of the rule collection group

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: the resource id of the rule\_collection\_group

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->