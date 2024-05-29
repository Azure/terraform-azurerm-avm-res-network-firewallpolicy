variable "firewall_policy_rule_collection_group_firewall_policy_id" {
  type        = string
  description = "(Required) The ID of the Firewall Policy where the Firewall Policy Rule Collection Group should exist. Changing this forces a new Firewall Policy Rule Collection Group to be created."
  nullable    = false
}

variable "firewall_policy_rule_collection_group_name" {
  type        = string
  description = "(Required) The name which should be used for this Firewall Policy Rule Collection Group. Changing this forces a new Firewall Policy Rule Collection Group to be created."
  nullable    = false
}

variable "firewall_policy_rule_collection_group_priority" {
  type        = number
  description = "(Required) The priority of the Firewall Policy Rule Collection Group. The range is 100-65000."
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

variable "firewall_policy_rule_collection_group_application_rule_collection" {
  type = list(object({
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
  default     = null
  description = <<-EOT
 - `action` - (Required) The action to take for the application rules in this collection. Possible values are `Allow` and `Deny`.
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
EOT
}

variable "firewall_policy_rule_collection_group_nat_rule_collection" {
  type = list(object({
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
  default     = null
  description = <<-EOT
 - `action` - (Required) The action to take for the NAT rules in this collection. Currently, the only possible value is `Dnat`.
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
EOT
}

variable "firewall_policy_rule_collection_group_network_rule_collection" {
  type = list(object({
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
  default     = null
  description = <<-EOT
 - `action` - (Required) The action to take for the network rules in this collection. Possible values are `Allow` and `Deny`.
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
EOT
}

variable "firewall_policy_rule_collection_group_timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  default     = null
  description = <<-EOT
 - `create` - (Defaults to 30 minutes) Used when creating the Firewall Policy Rule Collection Group.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Firewall Policy Rule Collection Group.
 - `read` - (Defaults to 5 minutes) Used when retrieving the Firewall Policy Rule Collection Group.
 - `update` - (Defaults to 30 minutes) Used when updating the Firewall Policy Rule Collection Group.
EOT
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

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:
  
  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  nullable    = false
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
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.
  
  > Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
  DESCRIPTION
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) A mapping of tags to assign to the resource."
}
