# -----------------------------------------------------------------------------
# Azure Firewall Policy, migrated from `hashicorp/azurerm` to `Azure/azapi`
# IN PLACE. The public variable surface is unchanged, the resource boundary is
# unchanged, and every `for_each`/`count` key is unchanged -- so a consumer
# bumps the module version and nothing else.
#
# THE SHAPE, in one sentence: ONE PLAIN FULL WRITER per resource, no
# create-only/merge-writer split.
#
# 🔴 THAT IS A DELIBERATE DIFFERENCE FROM `azurerm_firewall` IN
# `terraform-azurerm-avm-ptn-alz-connectivity-virtual-wan`, WHICH USES THE
# CANDIDATE-1 SPLIT. The split exists to stop a full PUT from deleting child
# collections that live INSIDE the resource body. A firewall policy has no such
# collections:
#
#   - `properties.ruleCollectionGroups` is `readOnly` in the 2025-07-01 body
#     type, and so are `properties.firewalls`, `properties.childPolicies`,
#     `properties.size` and `properties.provisioningState`. A PUT cannot carry
#     them and cannot drop them; ARM owns them.
#   - RULE COLLECTION GROUPS ARE SEPARATE CHILD **RESOURCES**
#     (`Microsoft.Network/firewallPolicies/ruleCollectionGroups`), written by
#     the `modules/rule_collection_groups` submodule against their own ARM
#     endpoint. They are not members of this body, so this body's PUT cannot
#     touch them. Contrast `azurerm_firewall`, whose
#     `applicationRuleCollections` / `networkRuleCollections` /
#     `natRuleCollections` ARE inline members -- which is precisely why
#     AzureRM hand-rolled a GET-and-carry-forward there and why the vWAN module
#     needed candidate 1.
#   - AZURERM ITSELF DID A FULL UNCONDITIONAL PUT HERE. `Create` and `Update`
#     are the same function (`firewall_policy_resource.go` L60); it builds the
#     body from scratch, issues no GET, carries nothing forward, and calls
#     `CreateOrUpdateThenPoll`. A full writer is therefore PARITY, not a new
#     hazard.
#   - AND THE SPLIT WOULD COST SOMETHING REAL. `azapi_update_resource` merges,
#     so it can never REMOVE a tag or un-set a property -- the additive-only
#     regression recorded as REG-1. Adopting candidate 1 here would import that
#     regression to buy protection against a hazard that does not exist.
#
# What this module does NOT declare from the writable 2025-07-01 body:
# `properties.dnsSettings.requireProxyForNetworkRules` and
# `properties.intrusionDetection.profile`. AzureRM v4.81.0 had no schema field
# for either, so under a full PUT they are omitted exactly as often as they
# were before this migration -- unchanged exposure, not new exposure. A
# consumer who needs one uses `var.ignore_body_changes`.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# AVM STANDARD INTERFACES. `Azure/avm-utl-interfaces/azure` turns the three
# standard AVM variables into ARM request bodies so that every AVM module
# composes them identically. This is the same call the already-migrated
# `Azure/avm-res-resources-resourcegroup/azurerm` makes.
#
# 🔴 `lock.notes` IS SYNTHESISED HERE, NOT PASSED THROUGH. `var.lock` is the
# published AVM interface shape -- `{kind, name}` -- and it has no `notes`
# member, while the interfaces module's `lock` object does. The old
# `azurerm_management_lock.this` set `notes` from a fixed ternary on `kind`
# (`main.tf` L182 before this migration). Reproducing that ternary here keeps
# `properties.notes` byte-identical for an adopted lock; passing `var.lock`
# straight through would send `notes = null` and diff against every lock this
# module has ever created. `var.lock` deliberately does NOT gain a `notes`
# member -- that would change a published AVM interface variable, which an
# in-place provider migration must not do.
#
# `role_assignment_definition_scope` is required whenever `role_assignments` is
# non-empty: the interfaces module resolves a role definition NAME to its ID
# with a `data "azapi_resource_list"` at that scope. The old module did the
# same job with `strcontains(...)` against
# `local.role_definition_resource_substring`, handing the name to AzureRM's
# `role_definition_name` argument; that local is gone because the lookup now
# lives in the interfaces module.
# -----------------------------------------------------------------------------
module "interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.6.0"

  diagnostic_settings = var.diagnostic_settings
  enable_telemetry    = var.enable_telemetry
  lock = var.lock == null ? null : {
    kind  = var.lock.kind
    name  = var.lock.name
    notes = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
  }
  role_assignment_definition_scope = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  role_assignments                 = var.role_assignments
}

# -----------------------------------------------------------------------------
# THE FIREWALL POLICY.
# -----------------------------------------------------------------------------
resource "azapi_resource" "this" {
  # `location`, `name` and `tags` are azapi's NATIVE attributes, not body
  # members, and that is load-bearing rather than stylistic: `flattenBody`
  # (azapi `internal/services/resource.go` L167-L187, v2.13.0) DELETES
  # `location`, `tags`, `name` and `identity` from the body it writes into
  # state after a `moved` adoption. A body carrying any of them would diff
  # against that state forever. See the header of `locals.tf`.
  location  = var.location
  name      = var.name
  parent_id = local.firewall_policy_parent_id
  type      = var.resource_types.network_firewall_policies
  body      = local.firewall_policy_body
  # ✅ TFFR8 (Severity-MUST, Class-Pattern): `ignore_body_changes` MUST be
  # configurable by the consumer and MUST NOT be omitted. The collapse-to-null
  # form keeps this write-only argument ABSENT at the `[]` default, so a
  # consumer on Terraform < 1.11 is unaffected by its mere presence.
  ignore_body_changes = length(var.ignore_body_changes.network_firewall_policies) > 0 ? (
    var.ignore_body_changes.network_firewall_policies
  ) : null
  # 🔴 THE CONTRACT THAT MAKES EVERY `null` IN `local.firewall_policy_body`
  # MEAN "ABSENT". Without this the provider would send explicit JSON nulls and
  # an adopted policy would diff on every optional the consumer never set. With
  # it, `updateObjectAtPath`'s `case value == nil && option.IgnoreNullProperty`
  # branch drops the key, reproducing AzureRM's `*T` + `omitempty`.
  ignore_null_property = true
  # 🔴 FORCENEW PARITY FOR `sku`. AzureRM marked `sku` ForceNew
  # (`firewall_policy_resource.go` L677) -- changing the tier destroyed and
  # recreated the policy. `azapi_resource` already treats `name`, `location`
  # and `parent_id` as replacement triggers, which covers AzureRM's other three
  # ForceNew fields, but a body property needs this.
  #
  # ✅ IT WORKS ON THIS ADDRESS, unlike on the vWAN pattern's
  # `azapi_update_resource`-backed gateways where it is a documented no-op.
  # The mechanism (`azapi_resource.go` L737-L776) JMESPath-extracts the path
  # from `state.Body` and from `plan.Body` and calls `RequiresReplace` when
  # they differ. That is dead code when `body` sits in `ignore_changes`,
  # because then `plan.Body` IS `state.Body` by construction. Here `body` is
  # NOT ignored, so the two really can differ and the trigger really fires.
  #
  # ✅ AND IT IS SAFE AT ADOPTION. AzureRM's schema carries `Default:
  # "Standard"` and its `d.GetOk("sku")` guard is true for any non-empty
  # string, so `properties.sku.tier` was on EVERY request AzureRM ever made.
  # The migrated `state.Body` therefore always has it, `local.firewall_policy_body`
  # always has it, and on an unchanged configuration the two are equal.
  replace_triggers_refs = ["properties.sku.tier"]
  # ✅ TFFR4 (Severity-MUST, Class-Pattern): declared on every AzAPI resource,
  # "even if empty". `[]` is correct -- `outputs.tf` reads `.id` and the body
  # inputs, never `.output`, so nothing needs an export and a computed
  # `.output` stays out of the module's outputs.
  #
  # 🔴 IT IS DELIBERATELY *NOT* PAIRED WITH AN `ignore_changes` ENTRY.
  # An earlier design pinned this attribute with
  # `lifecycle { ignore_changes = [response_export_values] }` to buy a quiet
  # adoption plan. That pairing was WITHDRAWN -- it broke the first apply after
  # adoption, which is the customer path. The mechanism, read out of azapi
  # v2.13.0 rather than inferred:
  #
  #   - `buildOutputFromBody` (`internal/services/common.go` L24-L34) branches on
  #     `response_export_values` being NULL. Null does NOT mean "export nothing";
  #     it means "export the DEFAULT output", which is
  #     `id.ResourceDef.GetReadOnly(responseBody)` minus `volatileFieldList()`
  #     (`azapi_resource.go` L1078-L1083). For a firewall policy that default
  #     includes `properties.size` -- a string ARM RECOMPUTES on every write and
  #     which is NOT on the volatile-field list.
  #   - `MoveState` (`azapi_resource.go` L1478) leaves `response_export_values`
  #     NULL in the post-move state, so the adopted resource's `output` is that
  #     full read-only projection, `properties.size` included.
  #   - `ignore_changes` pinned the PLANNED value to that null, so
  #     `!plan.ResponseExportValues.Equal(state.ResponseExportValues)`
  #     (`azapi_resource.go` L696) was false and `plan.Output` stayed KNOWN at
  #     the refreshed value.
  #   - The first apply still PUTs -- `ignore_null_property`, `retry` and
  #     `timeouts` all change at adoption even when the BODY does not. ARM
  #     recomputes `properties.size`, the post-apply `output` no longer matches
  #     the planned one, and Terraform aborts with
  #     "Provider produced inconsistent result after apply ...
  #     .output.properties.size". This occurred on two of four policies tested --
  #     exactly the two whose bodies had no diff, i.e. the ordinary
  #     default-shaped policy.
  #
  # WITHOUT THE PIN, `[]` is an empty LIST, not null, so `buildOutputFromBody`
  # takes the `flattenOutput(responseBody, [])` branch and `output` is `{}`
  # FOREVER -- no ARM-recomputed value is ever tracked, so the inconsistency
  # cannot recur on this apply or any later one. At adoption the null-vs-`[]`
  # difference pushes `plan.Output` unknown, which is what makes the apply legal.
  #
  # ⚠️ THE PRICE, stated plainly: the FIRST plan after adoption is an in-place
  # UPDATE, not a no-op. An unknown `plan.Output` also trips the deferred
  # closure at the top of `ModifyPlan` (`if plan.Output.IsUnknown() { plan.Body =
  # config.Body }`), so the plan shows `body` moving from the full refreshed
  # body to this module's configured subset. The resulting PUT is a semantic
  # no-op against ARM -- AzureRM issued the same full unconditional PUT -- but
  # the plan is noisy. The SKILL bar for step 5 is "zero unintended destroys or
  # replacements", which this meets; the stricter "No changes" bar is NOT met
  # and was never met anyway (see the upgrade guide).
  #
  # ✅ NO INTERFACE CHANGE. `output` is not reachable through any module output:
  # `outputs.tf` never reads `azapi_resource.*.output`, and the three read-only
  # back-references come from `data.azapi_resource.this` instead (see `data.tf`).
  response_export_values = []
  # 🔴 NOT a bare `retry = var.retry` -- see `local.azapi_retry` in `locals.tf`.
  # The provider marks `retry.error_message_regex` REQUIRED inside an optional
  # object, so a present object with a null regex list is unplannable.
  retry = local.azapi_retry
  # AzureRM parity: `tags.Expand` never returned nil, so an unset `tags` sent
  # `{}`. azapi's `tagsWithDefaultTags` (`azapi_resource.go` L1588-L1591) has
  # an explicit case for exactly that -- a null config against an empty state
  # returns the state -- so passing `var.tags` through unchanged produces no
  # diff for a policy that has no tags, and still REMOVES tags when the
  # consumer clears them. Removal is a real full-writer capability that the
  # merge-writer shape (REG-1) would have lost.
  tags = var.tags

  # AzureRM set `Identity` only when the expanded identity was not
  # `TypeNone`, i.e. only when the block was present. A `dynamic` block
  # reproduces that: absent variable, absent identity.
  #
  # ⚠️ The identity lives on azapi's NATIVE `identity` block, NOT in `body`,
  # for the `flattenBody` reason above. `Read` repopulates `state.Identity`
  # from the live GET, so an adopted policy's identity is already in state
  # before the first plan.
  dynamic "identity" {
    for_each = var.firewall_policy_identity == null ? [] : [var.firewall_policy_identity]

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  # `firewall_policy_resource.go` L52-57: Create 30m, Read 5m, Update 30m,
  # Delete 30m. `local.timeouts` layers `var.timeouts`, then the legacy
  # `var.firewall_policy_timeouts`, then those AzureRM defaults, so a consumer
  # who set neither keeps exactly the timeouts they had.
  #
  # The `dynamic "timeouts"` wrapper that used to sit on the AzureRM resource
  # is gone: it emitted the block only when `var.firewall_policy_timeouts` was
  # non-null, which meant an unset variable fell through to the PROVIDER
  # default rather than to AzureRM's. A static block with explicit fallbacks is
  # both simpler and closer to the old behaviour.
  timeouts {
    create = local.timeouts.network_firewall_policies.create
    delete = local.timeouts.network_firewall_policies.delete
    read   = local.timeouts.network_firewall_policies.read
    update = local.timeouts.network_firewall_policies.update
  }
}

# -----------------------------------------------------------------------------
# MANAGEMENT LOCK. `count` and key are unchanged from
# `azurerm_management_lock.this`, so the move is a whole-resource move.
#
# `coalesce(module.interfaces.lock_azapi.name, "lock-${var.lock.kind}")`
# reproduces the old `coalesce(var.lock.name, "lock-${var.lock.kind}")`
# exactly -- the interfaces module passes `var.lock.name` straight through, so
# the fallback is still this module's.
# -----------------------------------------------------------------------------
resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(module.interfaces.lock_azapi.name, "lock-${var.lock.kind}")
  parent_id = azapi_resource.this.id
  type      = var.resource_types.authorization_locks
  body      = module.interfaces.lock_azapi.body
  ignore_body_changes = length(var.ignore_body_changes.authorization_locks) > 0 ? (
    var.ignore_body_changes.authorization_locks
  ) : null
  response_export_values = []
  # 🔴 NOT a bare `retry = var.retry` -- see `local.azapi_retry` in `locals.tf`.
  retry = local.azapi_retry

  timeouts {
    create = local.timeouts.authorization_locks.create
    delete = local.timeouts.authorization_locks.delete
    read   = local.timeouts.authorization_locks.read
    update = local.timeouts.authorization_locks.update
  }
}

# -----------------------------------------------------------------------------
# ROLE ASSIGNMENTS. `for_each` keys are the consumer's `var.role_assignments`
# keys, unchanged, so the move is key-for-key.
#
# 🔴 `ignore_changes = [name]` IS NOT OPTIONAL HERE.
# `avm-utl-interfaces` computes `name = coalesce(v.name, random_uuid[k].result)`.
# A role assignment created by the AzureRM provider has a SERVER-ASSIGNED GUID
# for a name, which the fresh `random_uuid` will never match -- and `name` is a
# replacement trigger on `azapi_resource`. Without this entry, every adopted
# role assignment plans as DESTROY-AND-CREATE, which is a real outage window on
# an RBAC assignment. The `avm-tf-migration` SKILL blesses this exact mitigation
# at L107-117.
#
# ✅ AND THERE IS AN ESCAPE HATCH: `var.role_assignments[*].name` is an
# ADDITIVE optional member (new in this version) that lets a consumer pin the
# real GUID, after which `ignore_changes` has nothing to hide. `name` is
# otherwise irrelevant to a role assignment's behaviour -- ARM derives nothing
# from it.
#
# 🔴 `ignore_null_property = true` IS NOT COSMETIC HERE -- IT FIXES A PERPETUAL
# DIFF. `avm-utl-interfaces` emits EVERY optional body member, using an explicit
# JSON `null` for the ones the consumer did not set. `principalType` is the one
# that bites: when it is left unset, this module PUTs `"principalType": null`,
# ARM accepts the write and then DERIVES the real value from the principal, and
# the next GET returns `"principalType": "User"`. Config says null, remote says
# "User", so `terraform plan` proposes an in-place update FOREVER -- and the
# update "succeeds" every time without ever converging, because ARM just
# re-derives the value again. Observed against a real deployment, not inferred: apply,
# then re-plan, and the identical `principalType = "User" -> null` diff is back.
#
# This flag is the honest fix, and it is AzureRM PARITY, not a new mechanism.
# `azurerm_role_assignment` carried `PrincipalType` as a `*string` with
# `omitempty`, so an unset value was simply ABSENT from the request -- ARM
# derived it and nothing ever diffed. `ignore_null_property` reproduces exactly
# that wire behaviour: azapi's `RemoveNullProperty` (`azapi_resource.go` L959)
# strips null members from the request body before the PUT, and the same flag
# feeds `UpdateObject` in the no-op suppression path (L673) so a remote value
# the config does not pin no longer registers as a change. Checked against the
# azapi v2.13.0 source, not assumed. `azapi_resource.this` and
# `azapi_resource.diagnostic_settings` already set this flag for the identical
# reason; this writer was the outlier.
#
# ⚠️ CONSEQUENCE, STATED PLAINLY: with this flag set, writing `null` to an
# optional body member no longer CLEARS that member server-side -- it leaves it
# at whatever ARM currently holds. That is precisely what the AzureRM provider
# did, so it is not a regression against the module being replaced, and the
# affected members (`description`, `condition`) are ones ARM does not let you
# unset independently anyway. Recorded as a behavioural note, not a defect.
#
# ⚠️ `skip_service_principal_aad_check` is accepted and IGNORED. AzureRM used
# it to suppress its own client-side AAD replication check; ARM has no
# equivalent request member, so the interfaces module does not emit one. The
# same condition is now handled by `var.retry`, whose default
# `error_message_regex` retries the `409 Conflict` that a not-yet-replicated
# principal produces. Recorded as a behavioural difference, not a bug.
# -----------------------------------------------------------------------------
resource "azapi_resource" "role_assignments" {
  for_each = module.interfaces.role_assignments_azapi

  name      = each.value.name
  parent_id = azapi_resource.this.id
  type      = var.resource_types.authorization_role_assignments
  body      = each.value.body
  ignore_body_changes = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? (
    var.ignore_body_changes.authorization_role_assignments
  ) : null
  # 🔴 See the `principalType` note above -- this is a perpetual-diff fix and
  # AzureRM `omitempty` parity, not a cosmetic flag.
  ignore_null_property   = true
  response_export_values = []
  # 🔴 NOT a bare `retry = var.retry` -- see `local.azapi_retry` in `locals.tf`.
  retry = local.azapi_retry

  timeouts {
    create = local.timeouts.authorization_role_assignments.create
    delete = local.timeouts.authorization_role_assignments.delete
    read   = local.timeouts.authorization_role_assignments.read
    update = local.timeouts.authorization_role_assignments.update
  }

  # ONLY `name`. The `response_export_values` pin was withdrawn -- see
  # `azapi_resource.this`. `name` stays, and the SKILL blesses it explicitly.
  lifecycle {
    ignore_changes = [
      name,
    ]
  }
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS. `for_each` keys are the consumer's
# `var.diagnostic_settings` keys, unchanged.
#
# ✅ THE `moved` BLOCK AT THE END OF THIS FILE WORKS DESPITE THE ODD AZURERM
# ID. `azurerm_monitor_diagnostic_setting` does not store an ARM resource ID;
# it stores `"{target_resource_id}|{name}"`
# (`monitor_diagnostic_setting_resource.go` L234, L346). `MoveState` does not
# hand that to the ID parser directly -- it goes through
# `deriveAzureArmIdFromAzurermState` -> `parse.AzurermIdToAzureId`
# (`internal/services/parse/azurerm_resource_id.go`), which has a CASE for
# `azurerm_monitor_diagnostic_setting` that splits on the pipe and rebuilds
# `{target}/providers/Microsoft.Insights/diagnosticSettings/{name}`. Checked at
# azapi v2.13.0, not assumed.
#
# `coalesce(each.value.name, "diag-${var.name}")` reproduces the old
# `each.value.name != null ? each.value.name : "diag-${var.name}"`. The
# interfaces module passes `name` through unchanged (it does NOT invent one),
# so the fallback has to stay here or every unnamed diagnostic setting would be
# renamed -- and `name` is a replacement trigger.
#
# ⚠️ NOTE: the interfaces module adds a validation this module never had
# -- `log_categories` and `log_groups` may not BOTH be non-empty. Because
# `log_groups` defaults to `["allLogs"]`, a consumer who sets `log_categories`
# without clearing `log_groups` now gets a plan-time validation error where
# AzureRM silently emitted both sets of `enabled_log` blocks.
# -----------------------------------------------------------------------------
resource "azapi_resource" "diagnostic_settings" {
  for_each = module.interfaces.diagnostic_settings_azapi

  name      = coalesce(each.value.name, "diag-${var.name}")
  parent_id = azapi_resource.this.id
  type      = var.resource_types.insights_diagnostic_settings
  body      = each.value.body
  ignore_body_changes = length(var.ignore_body_changes.insights_diagnostic_settings) > 0 ? (
    var.ignore_body_changes.insights_diagnostic_settings
  ) : null
  # The interfaces body emits an explicit `null` for every destination the
  # consumer did not set. AzureRM omitted those members, so they are pruned
  # rather than sent -- same contract as the policy above.
  ignore_null_property   = true
  response_export_values = []
  # 🔴 NOT a bare `retry = var.retry` -- see `local.azapi_retry` in `locals.tf`.
  retry = local.azapi_retry

  # `monitor_diagnostic_setting_resource.go` L43-48 -- AzureRM's own defaults
  # for THIS resource, which are not the policy's: Create 30m, Read 5m,
  # Update 30m, Delete **60m**.
  timeouts {
    create = local.timeouts.insights_diagnostic_settings.create
    delete = local.timeouts.insights_diagnostic_settings.delete
    read   = local.timeouts.insights_diagnostic_settings.read
    update = local.timeouts.insights_diagnostic_settings.update
  }
}

# =============================================================================
# AzureRM -> AzAPI state moves (`avm-tf-migration` SKILL.md L66-78)
#
# The provider migration is IN PLACE: same module, same `for_each`/`count`
# boundary, same keys, so every move below is a whole-resource move and the
# consumer only bumps the module version. There is no `terraform state mv`, no
# import block and no removal of anything from state.
#
# The submodule's own move lives in
# `modules/rule_collection_groups/main.tf`, because an in-module `moved` block
# has to be declared in the module that owns both addresses.
#
# ✅ THE MIGRATED `type` MATCHES THE CONFIGURED `type` ON ALL FOUR ADDRESSES,
# and that was verified rather than assumed. `MoveState` writes
# `"{resourceType}@{apiVersion}"` into state using
# `parse.ResourceIDWithApiVersionInfo` (`parse/resource.go` L213), which picks
# `candidateApiVersions[len-1]` -- the LATEST api version embedded in the azapi
# binary for that type. At azapi v2.13.0 those latest versions are:
#
#   Microsoft.Network/firewallPolicies          2025-07-01
#   Microsoft.Authorization/locks               2020-05-01   (only version)
#   Microsoft.Authorization/roleAssignments     2022-04-01   (only version)
#   Microsoft.Insights/diagnosticSettings       2021-05-01-preview (only version)
#
# `var.resource_types` defaults to exactly those four, so `plan.Type` equals
# `state.Type` at adoption and the `!plan.Type.Equal(state.Type)` branch that
# would otherwise push `plan.Output` to unknown never fires.
#
# ⚠️ PLAN WITH A NORMAL REFRESH. The migrated state carries only `id`, `name`,
# `parent_id` and `type`; `state.body` is filled in by the first `Read`, which
# is gated on the `move_state` private flag (`azapi_resource.go` L1281).
# `-refresh=false` skips that read, leaves `state.body` null, and plans a
# REPLACE (azapi#1227).
# =============================================================================

moved {
  from = azurerm_firewall_policy.this
  to   = azapi_resource.this
}

moved {
  from = azurerm_management_lock.this[0]
  to   = azapi_resource.lock[0]
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignments
}

moved {
  from = azurerm_monitor_diagnostic_setting.this
  to   = azapi_resource.diagnostic_settings
}
