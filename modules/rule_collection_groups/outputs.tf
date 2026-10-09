# =============================================================================
# 🔴 `output "resource"` IS NO LONGER AN `azurerm_*` OBJECT.
#
# It used to be the whole `azurerm_firewall_policy_rule_collection_group.this`
# object, so it carried that resource's schema: `firewall_policy_id`, `name`,
# `priority`, and the nested `application_rule_collection` /
# `nat_rule_collection` / `network_rule_collection` blocks. AzAPI has a
# different schema, and a provider swap cannot preserve one provider's
# attribute names in another's.
#
# WHAT STILL WORKS:
#
#     module.<x>.resource_id          -- unchanged, the ARM resource ID
#     module.<x>.resource.id          -- unchanged
#     module.<x>.resource.name        -- unchanged
#
# WHAT MOVED:
#
#     .resource.firewall_policy_id            -> .resource.parent_id
#     .resource.priority                      -> .resource.body.properties.priority
#     .resource.application_rule_collection   -.
#     .resource.network_rule_collection        |-> .resource.body.properties.ruleCollections
#     .resource.nat_rule_collection           -'
#
# ⚠️ `.resource.body` is the CONFIGURED body, not the live one, and the three
# collection kinds are no longer separate attributes -- they are one
# `ruleCollections` array discriminated by `ruleCollectionType`, in the order
# application / network / NAT. See `locals.tf` for why that order is fixed.
# =============================================================================


output "name" {
  description = "The name of the firewall policy rule collection group."
  value       = azapi_resource.this.name
}

output "resource" {
  description = <<-EOT
  The firewall policy rule collection group resource. Built explicitly from `azapi_resource.this` rather than exported wholesale, so that the write-only `ignore_body_changes` argument is never read.

  Examples:
  - module.<x>.resource.id
  - module.<x>.resource.name
  - module.<x>.resource.body.properties.priority
  - module.<x>.resource.body.properties.ruleCollections
  EOT
  value = {
    body      = azapi_resource.this.body
    id        = azapi_resource.this.id
    name      = azapi_resource.this.name
    parent_id = azapi_resource.this.parent_id
    type      = azapi_resource.this.type
  }
}

output "resource_id" {
  description = "the resource id of the rule_collection_group"
  value       = azapi_resource.this.id
}
