variable "firewall_policy_rule_collection_group_firewall_policy_id" {
  type        = string
  description = "(Required) The ID of the Firewall Policy where the Firewall Policy Rule Collection Group should exist. Changing this forces a new Firewall Policy Rule Collection Group to be created."
  nullable    = false

  # TFNFR38. This value is `parent_id` on `azapi_resource.this`, which is a
  # replacement trigger, so a malformed or subtly different ID destroys and
  # recreates the rule collection group rather than failing the plan. The
  # validation catches it before that can happen.
  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Network/firewallPolicies", var.firewall_policy_rule_collection_group_firewall_policy_id))
    error_message = "`firewall_policy_rule_collection_group_firewall_policy_id` must be a valid Azure Firewall Policy resource ID."
  }
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

variable "firewall_policy_rule_collection_group_application_rule_collection" {
  type = list(object({
    action   = string
    name     = string
    priority = number
    rule = list(object({
      description           = optional(string)
      destination_addresses = optional(list(string), [])
      destination_fqdn_tags = optional(list(string), [])
      destination_fqdns     = optional(list(string), [])
      destination_urls      = optional(list(string), [])
      name                  = string
      source_addresses      = optional(list(string), [])
      source_ip_groups      = optional(list(string), [])
      terminate_tls         = optional(bool)
      web_categories        = optional(list(string), [])
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
      destination_ports   = optional(list(string), [])
      name                = string
      protocols           = list(string)
      source_addresses    = optional(list(string), [])
      source_ip_groups    = optional(list(string), [])
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

  # AzureRM enforced this inside the expander and failed at APPLY time
  # (`firewall_policy_rule_collection_group_resource.go` L719-L724:
  # "one and only one of `translated_address` and `translated_fqdn` must be
  # specified"). The AzAPI body has no equivalent guard -- it would simply omit
  # both members and let ARM reject the request -- so the same rule is restated
  # here as a `validation`, which fails at PLAN time instead. Strictly an
  # improvement in when the error surfaces, not a change in what is legal.
  #
  # ⚠️ The emptiness test is "null OR empty string", not `x == null`, because
  # AzureRM's guards were `!= ""` on a `TypeString` -- an explicit `""` counted
  # as UNSET there and must count as unset here too.
  #
  # 🔴 IT IS SPELLED OUT LONGHAND, NOT AS `coalesce(x, "") == ""`. Terraform's
  # `coalesce` returns the first argument that is neither null NOR an empty
  # string; with `x = null` the only remaining candidate is `""`, which it also
  # rejects, so the call fails outright with "no non-null, non-empty-string
  # arguments" instead of evaluating to `true`. Every legal NAT rule leaves
  # exactly one of these two members unset, so the `coalesce` form made
  # `firewall_policy_rule_collection_group_nat_rule_collection` impossible to
  # plan at all. Found by upgrade-path testing.
  validation {
    condition = alltrue([
      for collection in coalesce(var.firewall_policy_rule_collection_group_nat_rule_collection, []) : alltrue([
        for rule in collection.rule :
        (rule.translated_address == null || rule.translated_address == "") != (rule.translated_fqdn == null || rule.translated_fqdn == "")
      ])
    ])
    error_message = "Each NAT rule must set exactly one of `translated_address` or `translated_fqdn`."
  }
}

variable "firewall_policy_rule_collection_group_network_rule_collection" {
  type = list(object({
    action   = string
    name     = string
    priority = number
    rule = list(object({
      description           = optional(string)
      destination_addresses = optional(list(string), [])
      destination_fqdns     = optional(list(string), [])
      destination_ip_groups = optional(list(string), [])
      destination_ports     = list(string)
      name                  = string
      protocols             = list(string)
      source_addresses      = optional(list(string), [])
      source_ip_groups      = optional(list(string), [])
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

variable "ignore_body_changes" {
  type = object({
    network_firewall_policies_rule_collection_groups = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Body paths that Terraform must stop managing on the underlying `azapi_resource`.

This is the AzAPI escape hatch for a member of the request body that something outside Terraform owns -- a rule collection maintained by a policy engine, for instance. Each value is a list of JMESPath-style body paths.

- `network_firewall_policies_rule_collection_groups` - (Optional) Paths to ignore on the rule collection group, for example `["properties.ruleCollections"]`. Defaults to `[]`.

> Note: `ignore_body_changes` is a write-only argument and requires Terraform 1.11 or later. At the `[]` default the argument is omitted entirely, so earlier versions are unaffected.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for path in var.ignore_body_changes.network_firewall_policies_rule_collection_groups : length(trimspace(path)) > 0])
    error_message = "Every path in `ignore_body_changes.network_firewall_policies_rule_collection_groups` must be a non-empty string."
  }
}

variable "resource_types" {
  type = object({
    network_firewall_policies_rule_collection_groups = optional(string, "Microsoft.Network/firewallPolicies/ruleCollectionGroups@2025-07-01")
  })
  default     = {}
  description = <<DESCRIPTION
The ARM type and API version used for the underlying `azapi_resource`.

The default is not arbitrary and should not be changed without a reason. It is the LATEST API version embedded in `Azure/azapi` v2.13.0 for this type, which is the version `azapi_resource`'s state mover writes into state when the `moved` block adopts an existing `azurerm_firewall_policy_rule_collection_group`. Matching it keeps the state migration consistent; the first migration plan can still include in-place updates as AzAPI adopts existing resources.

- `network_firewall_policies_rule_collection_groups` - (Optional) Type of the rule collection group. Defaults to `Microsoft.Network/firewallPolicies/ruleCollectionGroups@2025-07-01`.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for t in values(var.resource_types) : can(regex("^[^/]+/[^@]+@[^@]+$", t))])
    error_message = "Every value in `resource_types` must be of the form `<Namespace>/<type>@<api-version>`."
  }
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["ScopeLocked", "CannotDeleteResource"])
    interval_seconds     = optional(number, null)
    max_interval_seconds = optional(number, null)
  })
  default     = {}
  description = <<DESCRIPTION
The retry configuration applied to the underlying `azapi_resource`.

Unlike the parent module this does NOT retry `409 Conflict`. The parent retries it because a freshly created service principal makes role assignments fail that way; a rule collection group has no such well-understood transient failure, and ARM already serialises writes to the same firewall policy, so retrying blindly would only hide a real error.

- `error_message_regex` - (Optional) A list of regular expressions matched against the error message. A match causes the request to be retried. Defaults to `["ScopeLocked", "CannotDeleteResource"]`, which covers TEARDOWN only: a management lock on the parent firewall policy is INHERITED by this rule collection group, and Terraform has no dependency edge between the parent's lock and this child, so a destroy can reach the group before the lock deletion has propagated. Set to `null` to disable retries entirely.
- `interval_seconds` - (Optional) Base number of seconds to wait between retries. Defaults to the AzAPI provider default (`10`).
- `max_interval_seconds` - (Optional) Maximum number of seconds to wait between retries. Defaults to the AzAPI provider default (`180`).

Setting `error_message_regex = null` - or any value that leaves it null - disables retries. The module collapses the whole object to `null` in that case, because the AzAPI provider marks `retry.error_message_regex` required inside an otherwise optional block and a present object with a null list cannot be planned.
DESCRIPTION
  nullable    = false
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
The timeouts applied to the underlying `azapi_resource`.

Each value must be a string parsable as a Go duration, for example `"30s"`, `"5m"` or `"1h30m"`.

A `null` value does NOT fall through to the AzAPI provider default. It falls through to the timeout `azurerm_firewall_policy_rule_collection_group` declared at `hashicorp/azurerm` v4.81.0 -- create `30m`, read `5m`, update `30m`, delete `30m` -- so an upgraded deployment keeps the behaviour it already had.

- `create` - (Optional) Timeout for create operations.
- `delete` - (Optional) Timeout for delete operations.
- `read` - (Optional) Timeout for read operations.
- `update` - (Optional) Timeout for update operations.

> Note: `var.firewall_policy_rule_collection_group_timeouts` still works. `var.timeouts` takes precedence over it.
DESCRIPTION
  nullable    = false
}
