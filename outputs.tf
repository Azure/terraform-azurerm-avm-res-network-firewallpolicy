# =============================================================================
# 🔴 READ THIS BEFORE USING `output "resource"`.
#
# It used to be the whole `azurerm_firewall_policy.this` object. It is now
# built from `azapi_resource.this`, and AZAPI'S ATTRIBUTE NAMES ARE NOT
# AZURERM'S. The members below are the ones this module commits to; anything
# else a consumer used to reach through `.resource` is gone, and there is no
# way to keep it -- a provider swap changes the resource schema by definition.
#
# WHAT STILL WORKS, unchanged, and is what every example and the
# `alz-connectivity-virtual-wan` pattern module actually use:
#
#     module.firewall_policy.resource_id
#     module.firewall_policy.resource.id
#     module.firewall_policy.resource.name
#     module.firewall_policy.resource.location
#     module.firewall_policy.resource.tags
#     module.firewall_policy.resource.firewalls
#     module.firewall_policy.resource.child_policies
#     module.firewall_policy.resource.rule_collection_groups
#
# WHAT MOVED. Configuration that AzureRM exposed as flat attributes now lives
# under `.resource.body.properties`, in ARM's member names:
#
#     .resource.sku                      -> .resource.body.properties.sku.tier
#     .resource.threat_intelligence_mode -> .resource.body.properties.threatIntelMode
#     .resource.base_policy_id           -> .resource.body.properties.basePolicy.id
#     .resource.private_ip_ranges        -> .resource.body.properties.snat.privateRanges
#
# ⚠️ `.resource.body` is the CONFIGURED body, not the live one. It contains
# only what this module writes; ARM-computed members are not in it.
#
# The three read-only back-references come from `data.azapi_resource.this`
# (see `data.tf` for why a data source may carry a non-empty
# `response_export_values` when no writer in this module may).
# =============================================================================


output "child_policies" {
  description = "The resource IDs of the child firewall policies of this firewall policy."
  value       = local.firewall_policy_child_policies
}

output "firewalls" {
  description = "The resource IDs of the Azure Firewalls this firewall policy is associated with."
  value       = local.firewall_policy_firewalls
}

output "location" {
  description = "The Azure Region the firewall policy is deployed to."
  value       = azapi_resource.this.location
}

output "name" {
  description = "The name of the firewall policy."
  value       = azapi_resource.this.name
}

output "resource" {
  description = <<-EOT
  "This is the full output for Firewall Policy resource. This is the default output for the module following AVM standards. Review the examples below for the correct output to use in your module."
  Examples:
  - module.firewall_policy.resource.id
  - module.firewall_policy.resource.firewalls
  - module.firewall_policy.resource.child_policies
  - module.firewall_policy.resource.rule_collection_groups
  EOT
  value = {
    body                   = azapi_resource.this.body
    child_policies         = local.firewall_policy_child_policies
    firewalls              = local.firewall_policy_firewalls
    id                     = azapi_resource.this.id
    identity               = azapi_resource.this.identity
    location               = azapi_resource.this.location
    name                   = azapi_resource.this.name
    parent_id              = azapi_resource.this.parent_id
    rule_collection_groups = local.firewall_policy_rule_collection_groups
    tags                   = azapi_resource.this.tags
    type                   = azapi_resource.this.type
  }
}

output "resource_id" {
  description = "the resource id of the firewall policy"
  value       = azapi_resource.this.id
}

output "rule_collection_groups" {
  description = "The resource IDs of the rule collection groups attached to this firewall policy. Populated from a live read, so a group created in the same apply does not appear until the next plan - see `data.tf`."
  value       = local.firewall_policy_rule_collection_groups
}
