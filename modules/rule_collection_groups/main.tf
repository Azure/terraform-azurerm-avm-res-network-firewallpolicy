# =============================================================================
# `azurerm_firewall_policy_rule_collection_group` -> `azapi_resource`.
#
# A SEPARATE `moved` BOUNDARY FROM THE PARENT MODULE. The policy and its rule
# collection groups are distinct ARM resources with distinct Terraform
# addresses, and this submodule is instantiated once per group by the caller
# (TFRMNFR1 -- one resource, single cardinality, no `for_each` in here). The
# `moved` block at the bottom therefore moves exactly one address per
# instantiation, and the caller's own module keys are what keep the mapping
# stable. Nothing in this file may change the module's address, its keys, or
# the resource's `name`.
#
# WHY A PLAIN FULL WRITER, with no `azapi_update_resource` companion:
# `resourceFirewallPolicyRuleCollectionGroupCreateUpdate`
# (`firewall_policy_rule_collection_group_resource.go` L462 at azurerm v4.81.0)
# is a single Create-and-Update function that rebuilds `properties` from the
# configuration on every apply, issues no GET, and PUTs the result whole. The
# resource has exactly two writable members -- `priority` and `ruleCollections`
# -- and no read-only child collections that a full PUT could clobber. A
# create-only body plus a merge writer would import the additive-only
# regression (REG-1: `azapi_update_resource` cannot REMOVE a member) in
# exchange for protecting nothing, and removing a rule collection is the single
# most common edit this resource sees.
# =============================================================================

resource "azapi_resource" "this" {
  # ⚠️ `name` and `parent_id` ARE BOTH NATIVE REPLACEMENT TRIGGERS on
  # `azapi_resource`, which is exactly the behaviour AzureRM had: `name` is
  # ForceNew (RCG L55) and `firewall_policy_id` is ForceNew (RCG L62). That is
  # also why this resource declares NO `replace_triggers_refs` -- there is no
  # third ForceNew field to reproduce, and `priority` and `ruleCollections` are
  # both genuinely updatable in place.
  name      = var.firewall_policy_rule_collection_group_name
  parent_id = var.firewall_policy_rule_collection_group_firewall_policy_id
  type      = var.resource_types.network_firewall_policies_rule_collection_groups
  body      = local.rule_collection_group_body
  # `ignore_body_changes` is how a consumer hands a member of this body to an
  # out-of-band controller -- a rule collection managed by a policy engine, for
  # instance -- without this module planning it back. Null rather than `[]`
  # when unused: the attribute is write-only and a null keeps it out of the
  # plan entirely.
  ignore_body_changes = length(var.ignore_body_changes.network_firewall_policies_rule_collection_groups) > 0 ? (var.ignore_body_changes.network_firewall_policies_rule_collection_groups) : null
  # 🔴 REQUIRED FOR PARITY, NOT AN OPTIMISATION. `locals.tf` emits `null` for
  # every member AzureRM omitted, and this flag is what turns those nulls into
  # OMITTED members instead of explicit JSON nulls. Without it the two
  # `*ProtocolS` members and `httpHeadersToInsert` would be PUT as literal
  # nulls on rules that do not use them.
  ignore_null_property = true
  # ✅ TFFR4: declared even though it is empty. `outputs.tf` never reads
  # `.output`, so nothing needs an export.
  #
  # 🔴 DELIBERATELY *NOT* PAIRED WITH `ignore_changes`. An earlier design
  # pinned this attribute to keep the adoption plan quiet. The pin
  # was WITHDRAWN because it breaks the first apply after adoption. In one
  # sentence: `buildOutputFromBody` (`internal/services/common.go` L24-L34)
  # treats a NULL `response_export_values` as "export the whole read-only
  # projection", `MoveState` (`azapi_resource.go` L1478) leaves it null,
  # `ignore_changes` pinned it there, `plan.Output` therefore stayed KNOWN at a
  # stale refreshed value, and the adoption PUT made Azure recompute that value
  # -- "Provider produced inconsistent result after apply". With `[]` actually
  # reaching the provider, `output` is `{}` and can never go stale. The full
  # write-up lives on `azapi_resource.this` in the parent `main.tf`.
  #
  # ⚠️ THE PRICE: the first plan after adoption is an in-place UPDATE, not a
  # no-op. Zero destroys and zero replacements, which is the SKILL bar.
  response_export_values = []
  # 🔴 THE WHOLE OBJECT IS COLLAPSED TO `null` WHEN NO REGEX IS CONFIGURED.
  # `azapi_resource.retry` is an optional single-nested attribute whose
  # `error_message_regex` member the PROVIDER marks REQUIRED, so handing it a
  # present object with a null regex list fails the plan outright with
  # "Must set a configuration value for the retry.error_message_regex
  # attribute as the provider has marked it as required." A bare
  # `retry = var.retry` is only ever safe while the regex list happens to be
  # non-null, and `retry = { interval_seconds = 30 }` is a perfectly legal
  # value of this variable's type. Found by upgrade-path testing,
  # where the submodule's then-null default made it impossible to
  # plan from the repository's own
  # `deploy_fw_policy_with_rule_collection_group` example. `terraform validate`
  # does not catch it; only a real plan does. The same guard is on all four
  # writers in the parent module.
  retry = var.retry.error_message_regex == null ? null : var.retry

  timeouts {
    create = local.timeouts.create
    delete = local.timeouts.delete
    read   = local.timeouts.read
    update = local.timeouts.update
  }
}

# =============================================================================
# STATE MOVES
#
# Every address this module used to manage, moved to the address that now
# manages it. These are in-module `moved` blocks, so a consumer upgrades by
# bumping the version -- no `terraform state mv`, no import blocks, no manual
# step. Terraform rewrites the state during plan and `azapi_resource.MoveState`
# converts the AzureRM state into AzAPI state in the same pass.
#
# ⚠️ Plan with a normal refresh -- see `docs/upgrade-guide.md`; `-refresh=false`
# hits azapi#1227 and plans a replace.
# =============================================================================

moved {
  from = azurerm_firewall_policy_rule_collection_group.this
  to   = azapi_resource.this
}
