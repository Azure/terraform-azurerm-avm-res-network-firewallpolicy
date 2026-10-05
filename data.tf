# The subscription this module's provider instance is pointed at. Used for two things only:
#
#   1. `local.firewall_policy_parent_id`, the resource group ID that `azapi_resource.this` needs
#      as its `parent_id`. AzureRM took `resource_group_name` and composed the same ID internally
#      (`firewallpolicies.NewFirewallPolicyID(subscriptionId, resourceGroupName, name)`,
#      `firewall_policy_resource.go` L67); this module now composes it explicitly.
#   2. `role_assignment_definition_scope` on `module.interfaces`, which needs a subscription scope
#      to resolve a role definition NAME to its ID.
#
# 🔴 THE PROVIDER ALIAS MATTERS. `data.azapi_client_config` reports the subscription of the AZAPI
# provider instance, which before this migration was irrelevant to where the policy landed --
# AzureRM's provider decided that. A consumer that passes only `providers = { azurerm = ... }`
# therefore silently moves the policy to whatever subscription the DEFAULT azapi provider points
# at. That is the vWAN repository's GUIDE DEFECT 2, reclassified there as a HIGH silent breaking
# change, and it applies verbatim to this module. Consumers MUST pass the azapi provider through.
#
# `main.telemetry.tf` declares its own `data "azapi_client_config" "telemetry"` because that one is
# gated on `var.enable_telemetry`; this one must exist unconditionally.
data "azapi_client_config" "current" {}

# =============================================================================
# READ-ONLY BACK-REFERENCES: `childPolicies`, `firewalls` and
# `ruleCollectionGroups`.
#
# WHY THIS DATA SOURCE EXISTS. The pre-migration `output "resource"` was the
# whole `azurerm_firewall_policy.this` object, and its own documentation
# advertised three members that are ARM-RESPONSE-ONLY data:
# `.firewalls`, `.child_policies` and `.rule_collection_groups` (AzureRM set
# them from `Computed` schema fields at `firewall_policy_resource.go`
# L218-L227). AzAPI surfaces response data in exactly ONE place -- the computed
# `output` attribute -- and `output` is populated by exactly one thing,
# `response_export_values`. Dropping the three would be a silent breaking
# change for any consumer reading them, which an in-place provider migration
# must not do.
#
# 🔴 WHY THE EXPORT LIST IS ALLOWED HERE AND NOWHERE ELSE IN THIS MODULE.
# Every WRITER in this module declares `response_export_values = []`, because a
# writer's `output` is part of what Terraform checks for consistency after an
# apply: any ARM-recomputed value that lands in it (`properties.size` on a
# firewall policy is the concrete offender) makes the apply abort with
# "Provider produced inconsistent result after apply". `[]` keeps a writer's
# `output` permanently `{}` and that class of failure permanently impossible.
# A DATA SOURCE HAS NO WRITER: it never PUTs, it has no `state.body`, there is
# no post-apply consistency check to violate, and its `response_export_values`
# cannot drag anything into an update. This is the maintainer's 2026-09-28
# ruling, applied in the vWAN pattern repository on
# `data "azapi_resource" "fw_hub_ip_addresses"` for the same reason.
#
# ⛔ DO NOT COPY A NON-EMPTY EXPORT LIST ONTO A WRITER IN THIS MODULE.
#
# THE PATHS ARE NARROW, NOT `["*"]`. Each is a JMESPath projection of a
# `SubResource[]` down to its `id`, which is exactly what AzureRM's
# `flattenNetworkSubResourceID` produced -- a list of resource ID strings.
#
# ⚠️ THE READ IS ONE APPLY BEHIND FOR RULE COLLECTION GROUPS. It depends only
# on `azapi_resource.this.id`, which is stable after create, so the outputs stay
# KNOWN at plan time instead of cascading unknowns through every consumer. The
# cost is that a rule collection group created in the SAME apply does not appear
# in `rule_collection_groups` until the next plan. Adding `depends_on` would fix
# that and would push an unknown through the outputs on every change; the
# outputs are worth more.
# =============================================================================
data "azapi_resource" "this" {
  resource_id = azapi_resource.this.id
  type        = var.resource_types.network_firewall_policies
  response_export_values = {
    child_policies         = "properties.childPolicies[].id"
    firewalls              = "properties.firewalls[].id"
    rule_collection_groups = "properties.ruleCollectionGroups[].id"
  }
}
