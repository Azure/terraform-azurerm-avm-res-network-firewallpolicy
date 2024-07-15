<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-network=firewallpolicy

This is the module to create an Azure Firewall Policy

"Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>"

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.71)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.71)

- <a name="provider_modtm"></a> [modtm](#provider\_modtm) (~> 0.3)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_firewall_policy.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/firewall_policy) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: (Required) The Azure Region where the Firewall Policy should exist. Changing this forces a new Firewall Policy to be created.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: (Required) The name which should be used for this Firewall Policy. Changing this forces a new Firewall Policy to be created.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: (Required) The name of the Resource Group where the Firewall Policy should exist. Changing this forces a new Firewall Policy to be created.

Type: `string`

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

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_firewall_policy_auto_learn_private_ranges_enabled"></a> [firewall\_policy\_auto\_learn\_private\_ranges\_enabled](#input\_firewall\_policy\_auto\_learn\_private\_ranges\_enabled)

Description: (Optional) Whether enable auto learn private ip range.

Type: `bool`

Default: `null`

### <a name="input_firewall_policy_base_policy_id"></a> [firewall\_policy\_base\_policy\_id](#input\_firewall\_policy\_base\_policy\_id)

Description: (Optional) The ID of the base Firewall Policy.

Type: `string`

Default: `null`

### <a name="input_firewall_policy_dns"></a> [firewall\_policy\_dns](#input\_firewall\_policy\_dns)

Description: - `proxy_enabled` - (Optional) Whether to enable DNS proxy on Firewalls attached to this Firewall Policy? Defaults to `false`.
- `servers` - (Optional) A list of custom DNS servers' IP addresses.

Type:

```hcl
object({
    proxy_enabled = optional(bool)
    servers       = optional(list(string))
  })
```

Default: `null`

### <a name="input_firewall_policy_explicit_proxy"></a> [firewall\_policy\_explicit\_proxy](#input\_firewall\_policy\_explicit\_proxy)

Description: - `enable_pac_file` - (Optional) Whether the pac file port and url need to be provided.
- `enabled` - (Optional) Whether the explicit proxy is enabled for this Firewall Policy.
- `http_port` - (Optional) The port number for explicit http protocol.
- `https_port` - (Optional) The port number for explicit proxy https protocol.
- `pac_file` - (Optional) Specifies a SAS URL for PAC file.
- `pac_file_port` - (Optional) Specifies a port number for firewall to serve PAC file.

Type:

```hcl
object({
    enable_pac_file = optional(bool)
    enabled         = optional(bool)
    http_port       = optional(number)
    https_port      = optional(number)
    pac_file        = optional(string)
    pac_file_port   = optional(number)
  })
```

Default: `null`

### <a name="input_firewall_policy_identity"></a> [firewall\_policy\_identity](#input\_firewall\_policy\_identity)

Description: - `identity_ids` - (Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Firewall Policy.
- `type` - (Required) Specifies the type of Managed Service Identity that should be configured on this Firewall Policy. Only possible value is `UserAssigned`.

Type:

```hcl
object({
    identity_ids = optional(set(string))
    type         = string
  })
```

Default: `null`

### <a name="input_firewall_policy_insights"></a> [firewall\_policy\_insights](#input\_firewall\_policy\_insights)

Description: - `default_log_analytics_workspace_id` - (Required) The ID of the default Log Analytics Workspace that the Firewalls associated with this Firewall Policy will send their logs to, when there is no location matches in the `log_analytics_workspace`.
- `enabled` - (Required) Whether the insights functionality is enabled for this Firewall Policy.
- `retention_in_days` - (Optional) The log retention period in days.

---
`log_analytics_workspace` block supports the following:
- `firewall_location` - (Required) The location of the Firewalls, that when matches this Log Analytics Workspace will be used to consume their logs.
- `id` - (Required) The ID of the Log Analytics Workspace that the Firewalls associated with this Firewall Policy will send their logs to when their locations match the `firewall_location`.

Type:

```hcl
object({
    default_log_analytics_workspace_id = string
    enabled                            = bool
    retention_in_days                  = optional(number)
    log_analytics_workspace = optional(list(object({
      firewall_location = string
      id                = string
    })))
  })
```

Default: `null`

### <a name="input_firewall_policy_intrusion_detection"></a> [firewall\_policy\_intrusion\_detection](#input\_firewall\_policy\_intrusion\_detection)

Description: - `mode` - (Optional) In which mode you want to run intrusion detection: `Off`, `Alert` or `Deny`.
- `private_ranges` - (Optional) A list of Private IP address ranges to identify traffic direction. By default, only ranges defined by IANA RFC 1918 are considered private IP addresses.

---
`signature_overrides` block supports the following:
- `id` - (Optional) 12-digit number (id) which identifies your signature.
- `state` - (Optional) state can be any of `Off`, `Alert` or `Deny`.

---
`traffic_bypass` block supports the following:
- `description` - (Optional) The description for this bypass traffic setting.
- `destination_addresses` - (Optional) Specifies a list of destination IP addresses that shall be bypassed by intrusion detection.
- `destination_ip_groups` - (Optional) Specifies a list of destination IP groups that shall be bypassed by intrusion detection.
- `destination_ports` - (Optional) Specifies a list of destination IP ports that shall be bypassed by intrusion detection.
- `name` - (Required) The name which should be used for this bypass traffic setting.
- `protocol` - (Required) The protocols any of `ANY`, `TCP`, `ICMP`, `UDP` that shall be bypassed by intrusion detection.
- `source_addresses` - (Optional) Specifies a list of source addresses that shall be bypassed by intrusion detection.
- `source_ip_groups` - (Optional) Specifies a list of source IP groups that shall be bypassed by intrusion detection.

Type:

```hcl
object({
    mode           = optional(string)
    private_ranges = optional(list(string))
    signature_overrides = optional(list(object({
      id    = optional(string)
      state = optional(string)
    })))
    traffic_bypass = optional(list(object({
      description           = optional(string)
      destination_addresses = optional(set(string))
      destination_ip_groups = optional(set(string))
      destination_ports     = optional(set(string))
      name                  = string
      protocol              = string
      source_addresses      = optional(set(string))
      source_ip_groups      = optional(set(string))
    })))
  })
```

Default: `null`

### <a name="input_firewall_policy_private_ip_ranges"></a> [firewall\_policy\_private\_ip\_ranges](#input\_firewall\_policy\_private\_ip\_ranges)

Description: (Optional) A list of private IP ranges to which traffic will not be SNAT.

Type: `list(string)`

Default: `null`

### <a name="input_firewall_policy_sku"></a> [firewall\_policy\_sku](#input\_firewall\_policy\_sku)

Description: (Optional) The SKU Tier of the Firewall Policy. Possible values are `Standard`, `Premium` and `Basic`. Changing this forces a new Firewall Policy to be created.

Type: `string`

Default: `null`

### <a name="input_firewall_policy_sql_redirect_allowed"></a> [firewall\_policy\_sql\_redirect\_allowed](#input\_firewall\_policy\_sql\_redirect\_allowed)

Description: (Optional) Whether SQL Redirect traffic filtering is allowed. Enabling this flag requires no rule using ports between `11000`-`11999`.

Type: `bool`

Default: `null`

### <a name="input_firewall_policy_threat_intelligence_allowlist"></a> [firewall\_policy\_threat\_intelligence\_allowlist](#input\_firewall\_policy\_threat\_intelligence\_allowlist)

Description: - `fqdns` - (Optional) A list of FQDNs that will be skipped for threat detection.
- `ip_addresses` - (Optional) A list of IP addresses or CIDR ranges that will be skipped for threat detection.

Type:

```hcl
object({
    fqdns        = optional(set(string))
    ip_addresses = optional(set(string))
  })
```

Default: `null`

### <a name="input_firewall_policy_threat_intelligence_mode"></a> [firewall\_policy\_threat\_intelligence\_mode](#input\_firewall\_policy\_threat\_intelligence\_mode)

Description: (Optional) The operation mode for Threat Intelligence. Possible values are `Alert`, `Deny` and `Off`. Defaults to `Alert`.

Type: `string`

Default: `null`

### <a name="input_firewall_policy_timeouts"></a> [firewall\_policy\_timeouts](#input\_firewall\_policy\_timeouts)

Description: - `create` - (Defaults to 30 minutes) Used when creating the Firewall Policy.
- `delete` - (Defaults to 30 minutes) Used when deleting the Firewall Policy.
- `read` - (Defaults to 5 minutes) Used when retrieving the Firewall Policy.
- `update` - (Defaults to 30 minutes) Used when updating the Firewall Policy.

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

### <a name="input_firewall_policy_tls_certificate"></a> [firewall\_policy\_tls\_certificate](#input\_firewall\_policy\_tls\_certificate)

Description: - `key_vault_secret_id` - (Required) The ID of the Key Vault, where the secret or certificate is stored.
- `name` - (Required) The name of the certificate.

Type:

```hcl
object({
    key_vault_secret_id = string
    name                = string
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

Description: "This is the full output for Firewall Policy resource. This is the default output for the module following AVM standards. Review the examples below for the correct output to use in your module."  
Examples:
- module.firewall\_policy.resource.id
- module.firewall\_policy.resource.firewalls
- module.firewall\_policy.resource.child\_policies
- module.firewall\_policy.resource.rule\_collection\_groups

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: the resource id of the firewall policy

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->