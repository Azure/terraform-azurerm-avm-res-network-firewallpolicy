
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

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the Resource Group where the Firewall Policy should exist. Changing this forces a new Firewall Policy to be created."
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

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")
  })
  default     = {}
  description = "The lock level to apply to the Firewall Policy. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`."
  nullable    = false

  validation {
    condition     = contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind)
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of role assignments to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - The description of the role assignment.
  - `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - The condition which will be used to scope the role assignment.
  - `condition_version` - The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  
  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION
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
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the resource."
}
