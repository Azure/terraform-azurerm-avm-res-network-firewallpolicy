# Rule id is `avm_interface_role_assignments` in tflint-ruleset-avm 1.0.0 (pinned by avm); it was `role_assignments` in 0.16.0.
# Disabled until this PR gets merged:
# https://github.com/Azure/tflint-ruleset-avm/pull/127
# The current rule rejects the optional `name` attribute on role_assignments
# that allows callers to pin a deterministic GUID for a role assignment.
#
# This module needs that attribute for a specific reason: the AzureRM -> AzAPI
# migration adopts existing `azurerm_role_assignment` resources with a `moved`
# block, and a role assignment created by AzureRM has a SERVER-ASSIGNED GUID
# for a name. `avm-utl-interfaces` would otherwise generate a fresh
# `random_uuid`, and `name` is a replacement trigger on `azapi_resource`, so
# every adopted assignment would plan as destroy-and-create. `main.tf` pins the
# name with `lifecycle.ignore_changes`; this attribute is the escape hatch that
# lets a consumer supply the real GUID instead.
rule "avm_interface_role_assignments" {
  enabled = false
}
