variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be deployed."
}

// Azure Firewall Policy
variable "fw_policy_name" {
  type        = string
  description = "The name of the Azure Firewall Policy."
}

variable "sku" {
  type        = string
  description = "The Azure Firewall Policy SKU."
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "The SKU must be one of the following: Basic, Standard, Premium"
  }
}

variable "proxy_enabled" {
  type        = bool
  description = "This variable controls whether or not telemetry is enabled for the module."
}

variable "dns_servers" {
  type        = list(string)
  description = <<DESCRIPTION
  The list of DNS servers to use for the Azure Firewall Policy.
  This will not be needed if the DNS proxy enabled is set to False
  DESCRIPTION
  default     = []
}

variable "threat_intel_mode" {
  type        = string
  description = "The threat intelligence mode for the Azure Firewall Policy."
  validation {
    condition     = contains(["Alert", "Deny", "Off"], var.threat_intel_mode)
    error_message = "The threat intelligence mode must be one of the following: Alert, Deny, Off"
  }
}

// Azure Firewall Policy Resource Collection Group

variable "rule_collection_group" {
  type = map(object({
    name     = string
    priority = number
  }))
}

// Application Rule Collection
variable "app_rule_collection_name" {
  type        = string
  description = "The name of the Azure Firewall Policy Application Rule Collection."
}

variable "app_rule_collection_priority" {
  type        = number
  description = "The priority of the Azure Firewall Policy Application Rule Collection."
  validation {
    condition     = var.app_rule_collection_priority == null ? true : var.app_rule_collection_priority >= 100 && var.app_rule_collection_priority <= 65000
    error_message = "The priority must be between 100 and 65000"
  }
}

variable "app_rule_collection_action" {
  type        = string
  description = "value of the action for the Azure Firewall Policy Application Rule Collection."
  validation {
    condition     = contains(["Allow", "Deny"], var.app_rule_collection_action)
    error_message = "The acceptable values for app_rule_collection_action are Allow or Deny"
  }
}

// Application Rule Collection Rules

variable "app_rule" {
  type = map(object({
    name        = string
    description = optional(string)
    protocols = optional(list(object({
      type = string
      port = number
    })))
    source_address         = optional(list(string))
    source_ip_groups       = optional(list(string))
    destination_address    = optional(list(string))
    destination_urls       = optional(list(string))
    destination_fqdns      = optional(list(string))
    destination_fqdns_tags = optional(list(string))
    terminate_tls          = optional(bool)
    web_categories         = optional(list(string))
  }))

  description = <<DESCRIPTION
  The map of Application Rules to use for the Azure Firewall Policy
  Each object in the list must contain the following attributes:
  - `description`: (Optional) The description of the app rule
  - `protocols`: (Required) The protocols to use for the app rule
  - `type`: (Required) The type of protocol to use for the app rule
  - `port`: (Required) The port to use for the app rule
  - `source_address`: (Optional) The source address to use for the app rule
  - `source_ip_groups`: (Optional) The source ip groups to use for the app rule. Only use if your not using source_address. 
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
  DESCRIPTION
  validation {
    condition     = contains(["true", "false"], var.app_rule.terminate_tls)
    error_message = "The acceptable values for terminate_tls are true or false"
  }
}

// Network Rule Collection

variable "net_rule_collection_name" {
  type        = string
  description = "The name of the Azure Firewall Policy Network Rule Collection."
}

variable "net_rule_collection_priority" {
  type        = number
  description = "The priority of the Azure Firewall Policy Network Rule Collection."
}

variable "net_rule_collection_action" {
  type        = string
  description = "value of the action for the Azure Firewall Policy Network Rule Collection."
}

// Network Rule Collection Rules

variable "net_rule" {
  type = map(object({
    description           = optional(string)
    protocols             = string
    destination_ports     = list(number)
    source_address        = optional(list(string))
    source_ip_groups      = optional(list(string))
    destination_address   = optional(list(string))
    destination_ip_groups = optional(list(string))
    destination_fqdns     = optional(list(string))
  }))
  description = <<DESCRIPTION
  The map of Network Rules to use for the Azure Firewall Policy
  Each object in the list must contain the following attributes:
  - `description`: (Optional) The description of the net rule
  - `protocols`: (Required) The protocols to use for the net rule
  - `destination_ports`: (Required) The destination ports to use for the net rule
  - `source_address`: (Optional) The source address to use for the net rule
  - `source_ip_groups`: (Optional) The source ip groups to use for the net rule. Only use if your not using source_address.
  - `destination_address`: (Optional) The destination address to use for the net rule
  - `destination_ip_groups`: (Optional) The destination ip groups to use for the net rule. Only use if your not using destination_address.
  - `destination_fqdns`: (Optional) The destination fqdns to use for the net rule

  Example Input:
  ```terraform
  # Allow RDP to Virtual Machines
  rule {
    name = "AllowRDP"
    description = "Allow RDP to Virtual Machines"
    protocols = "TCP"
    destination_ports = [3389]
    source_address = ["*"]
    destination_address = ["*"]
  }
  ```
  DESCRIPTION
}

// NAT Rule Collection

variable "nat_rule_collection_name" {
  type        = string
  description = "The name of the Azure Firewall Policy NAT Rule Collection."
}

variable "nat_rule_collection_priority" {
  type        = number
  description = "The priority of the Azure Firewall Policy NAT Rule Collection."
}

variable "nat_rule_collection_action" {
  type        = string
  description = "value of the action for the Azure Firewall Policy NAT Rule Collection."
}

variable "nat_rule" {
  type = map(object({
    description           = optional(string)
    protocols             = string
    source_addresses      = optional(list(string))
    source_ip_groups      = optional(list(string))
    destination_addresses = optional(list(string))
    destination_ports     = optional(list(number))
    translated_address    = optional(string)
    translated_fqdn       = optional(string)
    translated_port       = number
  }))
  description = <<DESCRIPTION
  The map of NAT Rules to use for the Azure Firewall Policy
  Each object in the list must contain the following attributes:
  - `description`: (Optional) The description of the nat rule
  - `protocols`: (Required) The protocols to use for the nat rule
  - `source_addresses`: (Optional) The source addresses to use for the nat rule
  - `source_ip_groups`: (Optional) The source ip groups to use for the nat rule. Only use if your not using source_addresses.
  - `destination_addresses`: (Optional) The destination addresses to use for the nat rule
  - `destination_ports`: (Optional) The destination ports to use for the nat rule
  - `translated_address`: (Optional) The translated address to use for the nat rule. This is required if you are not using translated_fqdn
  - `translated_fqdn`: (Optional) The translated fqdn to use for the nat rule. This is required if you are not using translated_address
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

  DESCRIPTION

}
// NAT Rule Collection Rules

variable "diagnostic_settings" {
  type = map(object({
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
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
}


variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, true)
    condition                              = optional(string, null)
    condition_version                      = optional(string, "2.0")
    delegated_managed_identity_resource_id = optional(string)
  }))
  default = {}
}

variable "lock" {
  type = object({
    name = optional(string, null)
    kind = optional(string, "None")


  })
  description = "The lock level to apply to the Virtual Network. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`."
  default     = {}
  nullable    = false
  validation {
    condition     = contains(["CanNotDelete", "ReadOnly", "None"], var.lock.kind)
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}


# Example resource implementation

variable "tags" {
  type = map(any)
  default = {
  }
  description = <<DESCRIPTION
The tags to associate with your network and subnets.
DESCRIPTION
}