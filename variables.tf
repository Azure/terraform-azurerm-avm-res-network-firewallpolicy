variable "location" {
  type        = string
  description = "(Required) The Azure Region where the Firewall Policy should exist. Changing this forces a new Firewall Policy to be created."
  nullable    = false
}

variable "name" {
  type        = string
  description = "(Required) The name which should be used for this Firewall Policy. Changing this forces a new Firewall Policy to be created."
  nullable    = false
}

variable "diagnostic_settings" {
  type = map(object({
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
  default     = {}
  description = <<DESCRIPTION
  A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
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
  DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "firewall_policy_auto_learn_private_ranges_enabled" {
  type        = bool
  default     = null
  description = "(Optional) Whether enable auto learn private ip range."
}

variable "firewall_policy_base_policy_id" {
  type        = string
  default     = null
  description = "(Optional) The ID of the base Firewall Policy."
}

variable "firewall_policy_dns" {
  type = object({
    proxy_enabled = optional(bool)
    servers       = optional(list(string))
  })
  default     = null
  description = <<-EOT
 - `proxy_enabled` - (Optional) Whether to enable DNS proxy on Firewalls attached to this Firewall Policy? Defaults to `false`.
 - `servers` - (Optional) A list of custom DNS servers' IP addresses.
EOT
}

variable "firewall_policy_explicit_proxy" {
  type = object({
    enable_pac_file = optional(bool)
    enabled         = optional(bool)
    http_port       = optional(number)
    https_port      = optional(number)
    pac_file        = optional(string)
    pac_file_port   = optional(number)
  })
  default     = null
  description = <<-EOT
 - `enable_pac_file` - (Optional) Whether the pac file port and url need to be provided.
 - `enabled` - (Optional) Whether the explicit proxy is enabled for this Firewall Policy.
 - `http_port` - (Optional) The port number for explicit http protocol.
 - `https_port` - (Optional) The port number for explicit proxy https protocol.
 - `pac_file` - (Optional) Specifies a SAS URL for PAC file.
 - `pac_file_port` - (Optional) Specifies a port number for firewall to serve PAC file.
EOT
}

variable "firewall_policy_identity" {
  type = object({
    identity_ids = optional(set(string))
    type         = string
  })
  default     = null
  description = <<-EOT
 - `identity_ids` - (Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Firewall Policy.
 - `type` - (Required) Specifies the type of Managed Service Identity that should be configured on this Firewall Policy. Only possible value is `UserAssigned`.
EOT
}

variable "firewall_policy_insights" {
  type = object({
    default_log_analytics_workspace_id = string
    enabled                            = bool
    retention_in_days                  = optional(number)
    log_analytics_workspace = optional(list(object({
      firewall_location = string
      id                = string
    })))
  })
  default     = null
  description = <<-EOT
 - `default_log_analytics_workspace_id` - (Required) The ID of the default Log Analytics Workspace that the Firewalls associated with this Firewall Policy will send their logs to, when there is no location matches in the `log_analytics_workspace`.
 - `enabled` - (Required) Whether the insights functionality is enabled for this Firewall Policy.
 - `retention_in_days` - (Optional) The log retention period in days.

 ---
 `log_analytics_workspace` block supports the following:
 - `firewall_location` - (Required) The location of the Firewalls, that when matches this Log Analytics Workspace will be used to consume their logs.
 - `id` - (Required) The ID of the Log Analytics Workspace that the Firewalls associated with this Firewall Policy will send their logs to when their locations match the `firewall_location`.
EOT
}

variable "firewall_policy_intrusion_detection" {
  type = object({
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
  default     = null
  description = <<-EOT
 - `mode` - (Optional) In which mode you want to run intrusion detection: `Off`, `Alert` or `Deny`.
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
EOT
}

variable "firewall_policy_private_ip_ranges" {
  type        = list(string)
  default     = null
  description = "(Optional) A list of private IP ranges to which traffic will not be SNAT."
}

variable "firewall_policy_sku" {
  type        = string
  default     = null
  description = "(Optional) The SKU Tier of the Firewall Policy. Possible values are `Standard`, `Premium` and `Basic`. Changing this forces a new Firewall Policy to be created."
}

variable "firewall_policy_sql_redirect_allowed" {
  type        = bool
  default     = null
  description = "(Optional) Whether SQL Redirect traffic filtering is allowed. Enabling this flag requires no rule using ports between `11000`-`11999`."
}

variable "firewall_policy_threat_intelligence_allowlist" {
  type = object({
    fqdns        = optional(set(string))
    ip_addresses = optional(set(string))
  })
  default     = null
  description = <<-EOT
 - `fqdns` - (Optional) A list of FQDNs that will be skipped for threat detection.
 - `ip_addresses` - (Optional) A list of IP addresses or CIDR ranges that will be skipped for threat detection.
EOT
}

variable "firewall_policy_threat_intelligence_mode" {
  type        = string
  default     = null
  description = "(Optional) The operation mode for Threat Intelligence. Possible values are `Alert`, `Deny` and `Off`. Defaults to `Alert`."
}

variable "firewall_policy_timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` - (Defaults to 30 minutes) Used when creating the Firewall Policy.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Firewall Policy.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Firewall Policy.
 - `update` - (Defaults to 30 minutes) Used when updating the Firewall Policy.
EOT
}

variable "firewall_policy_tls_certificate" {
  type = object({
    key_vault_secret_id = string
    name                = string
  })
  default     = null
  description = <<-EOT
 - `key_vault_secret_id` - (Required) The ID of the Key Vault, where the secret or certificate is stored.
 - `name` - (Required) The name of the certificate.
EOT
}

variable "ignore_body_changes" {
  type = object({
    authorization_locks            = optional(list(string), [])
    authorization_role_assignments = optional(list(string), [])
    insights_diagnostic_settings   = optional(list(string), [])
    network_firewall_policies      = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body paths that Terraform must stop managing on each underlying `azapi_resource`, keyed by resource type.

This is the AzAPI escape hatch for a property that something outside Terraform owns. Each value is a list of JMESPath-style body paths, for example `["properties.intrusionDetection.profile"]`.

Two members of the 2025-07-01 firewall policy body are writable but have no module input, because `hashicorp/azurerm` had no schema field for them either: `properties.dnsSettings.requireProxyForNetworkRules` and `properties.intrusionDetection.profile`. Set them out of band and list them here if you need them.

- `authorization_locks` - (Optional) Paths to ignore on the management lock. Defaults to `[]`.
- `authorization_role_assignments` - (Optional) Paths to ignore on the role assignments. Defaults to `[]`.
- `insights_diagnostic_settings` - (Optional) Paths to ignore on the diagnostic settings. Defaults to `[]`.
- `network_firewall_policies` - (Optional) Paths to ignore on the firewall policy. Defaults to `[]`.

> Note: `ignore_body_changes` is a write-only argument and requires Terraform 1.11 or later. At the `[]` default the argument is omitted entirely, so earlier versions are unaffected.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for path in var.ignore_body_changes.authorization_locks : length(trimspace(path)) > 0])
    error_message = "Every path in `ignore_body_changes.authorization_locks` must be a non-empty string."
  }
  validation {
    condition     = alltrue([for path in var.ignore_body_changes.authorization_role_assignments : length(trimspace(path)) > 0])
    error_message = "Every path in `ignore_body_changes.authorization_role_assignments` must be a non-empty string."
  }
  validation {
    condition     = alltrue([for path in var.ignore_body_changes.insights_diagnostic_settings : length(trimspace(path)) > 0])
    error_message = "Every path in `ignore_body_changes.insights_diagnostic_settings` must be a non-empty string."
  }
  validation {
    condition     = alltrue([for path in var.ignore_body_changes.network_firewall_policies : length(trimspace(path)) > 0])
    error_message = "Every path in `ignore_body_changes.network_firewall_policies` must be a non-empty string."
  }
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:
  
  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "parent_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
(Optional) The resource ID of the Resource Group where the Firewall Policy should exist. Changing this forces a new Firewall Policy to be created.

The AVM-preferred alternative to `resource_group_name` (TFNFR38). Unlike `resource_group_name` it does not depend on the subscription the `azapi` provider is pointed at, so it is the safer input when the module is used across subscriptions. Supply this **or** `resource_group_name`, not both.
DESCRIPTION

  validation {
    condition     = var.parent_id == null || can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid Azure Resource Group resource ID."
  }
}

variable "resource_group_name" {
  type        = string
  default     = null
  description = <<DESCRIPTION
(Optional) The name of the Resource Group where the Firewall Policy should exist. Changing this forces a new Firewall Policy to be created.

Combined with the subscription of the `azapi` provider to build the resource group ID that the firewall policy is created under. Supply this **or** `parent_id`, not both. It is no longer required only because `parent_id` is the AVM-preferred spelling (TFNFR38); every existing caller can keep passing it and nothing changes.
DESCRIPTION

  validation {
    condition     = (var.parent_id == null) != (var.resource_group_name == null)
    error_message = "Set exactly one of `parent_id` or `resource_group_name`."
  }
}

variable "resource_types" {
  type = object({
    authorization_locks            = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    insights_diagnostic_settings   = optional(string, "Microsoft.Insights/diagnosticSettings@2021-05-01-preview")
    network_firewall_policies      = optional(string, "Microsoft.Network/firewallPolicies@2025-07-01")
  })
  default     = {}
  description = <<DESCRIPTION
The ARM type and API version used for each underlying `azapi_resource`.

The defaults are not arbitrary and should not be changed without a reason. Each one is the LATEST API version embedded in `Azure/azapi` v2.13.0 for that type, which is the version `azapi_resource`'s state mover writes into state when a `moved` block adopts an existing `azurerm_*` resource. Matching it keeps the state migration consistent; the first migration plan can still include in-place updates as AzAPI adopts existing resources.

- `authorization_locks` - (Optional) Type of the management lock. Defaults to `Microsoft.Authorization/locks@2020-05-01`.
- `authorization_role_assignments` - (Optional) Type of the role assignments. Defaults to `Microsoft.Authorization/roleAssignments@2022-04-01`.
- `insights_diagnostic_settings` - (Optional) Type of the diagnostic settings. Defaults to `Microsoft.Insights/diagnosticSettings@2021-05-01-preview`, which is also the version `hashicorp/azurerm` v4.81.0 used.
- `network_firewall_policies` - (Optional) Type of the firewall policy. Defaults to `Microsoft.Network/firewallPolicies@2025-07-01`.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for t in values(var.resource_types) : can(regex("^[^/]+/[^@]+@[^@]+$", t))])
    error_message = "Every value in `resource_types` must be of the form `<Namespace>/<type>@<api-version>`."
  }
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["409 Conflict", "ScopeLocked", "CannotDeleteResource"])
    interval_seconds     = optional(number, null)
    max_interval_seconds = optional(number, null)
  })
  default     = {}
  description = <<DESCRIPTION
The retry configuration applied to every underlying `azapi_resource` (firewall policy, lock, role assignments, diagnostic settings).

- `error_message_regex` - (Optional) A list of regular expressions matched against the error message. A match causes the request to be retried. Defaults to `["409 Conflict", "ScopeLocked", "CannotDeleteResource"]`.
  - `409 Conflict` covers the conflict a not-yet-replicated service principal returns on a role assignment - the case `skip_service_principal_aad_check` used to handle client-side under `hashicorp/azurerm`.
  - `ScopeLocked` and `CannotDeleteResource` cover TEARDOWN. A management lock on a firewall policy is INHERITED by every child scope, and Terraform has no dependency edge between `azapi_resource.lock` and its sibling `azapi_resource.role_assignments` / `azapi_resource.diagnostic_settings` - they all depend only on the policy, so Terraform is free to destroy them in parallel. Deleting a child before the lock deletion has propagated returns one of these two codes. Retrying lets the lock removal land and the delete succeed. Set this to `null` to disable retries entirely, which also disables that recovery.
- `interval_seconds` - (Optional) Base number of seconds to wait between retries. Defaults to the AzAPI provider default (`10`).
- `max_interval_seconds` - (Optional) Maximum number of seconds to wait between retries. Defaults to the AzAPI provider default (`180`).

Setting `error_message_regex = null` - or any value that leaves it null - disables retries. The module collapses the whole object to `null` in that case (see `local.azapi_retry`), because the AzAPI provider marks `retry.error_message_regex` required inside an otherwise optional block and a present object with a null list cannot be planned.
DESCRIPTION
  nullable    = false
}

variable "role_assignments" {
  type = map(object({
    name                                   = optional(string, null)
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name` - (Optional) The name (a GUID) of the role assignment. If not set, a random UUID is generated. The name is ignored after creation so an adopted assignment keeps its existing GUID. Set this before creation to choose a GUID; changing it later does not rename or replace the assignment.
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) Accepted for interface compatibility and **no longer used**. It suppressed a client-side Entra ID replication check inside the `azurerm` provider; ARM has no equivalent request member, so nothing is sent. The same condition is now absorbed by `var.retry`, whose default `error_message_regex` retries the `409 Conflict` a not-yet-replicated principal returns.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.
  DESCRIPTION
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the resource."
}

variable "timeouts" {
  type = object({
    create = optional(string, null)
    delete = optional(string, null)
    read   = optional(string, null)
    update = optional(string, null)
  })
  default     = {}
  description = <<DESCRIPTION
The timeouts applied to every underlying `azapi_resource` (firewall policy, lock, role assignments, diagnostic settings).

Each value must be a string parsable as a Go duration, for example `"30s"`, `"5m"` or `"1h30m"`.

A `null` value does NOT fall through to the AzAPI provider default. It falls through to the timeout the `hashicorp/azurerm` v4.81.0 resource this module used to declare had, so an upgraded deployment keeps the behaviour it already had:

| resource | create | read | update | delete |
|---|---|---|---|---|
| firewall policy | `30m` | `5m` | `30m` | `30m` |
| diagnostic settings | `30m` | `5m` | `30m` | `60m` |
| lock | `30m` | `5m` | `30m` | `30m` |
| role assignments | `30m` | `5m` | `30m` | `30m` |

- `create` - (Optional) Timeout for create operations.
- `delete` - (Optional) Timeout for delete operations.
- `read` - (Optional) Timeout for read operations.
- `update` - (Optional) Timeout for update operations.

> Note: `var.firewall_policy_timeouts` still works and still applies to the firewall policy only. `var.timeouts` takes precedence over it.
DESCRIPTION
  nullable    = false
}
