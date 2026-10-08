# terraform-azurerm-avm-network-firewallpolicy

This is the module to create an Azure Firewall Policy

## Upgrading from v0.3.4 and earlier

This release migrates the module and its `rule_collection_groups` submodule from the `azurerm`
provider to `azapi`. The in-module `moved` blocks map existing AzureRM state for the policy, rule
collection groups, lock, role assignments and diagnostic settings to their AzAPI resources. The
first refreshed plan can include in-place updates as AzAPI adopts the existing resources. Review all
planned actions and stop if any existing resource has an unexpected destroy or replacement. After
applying the migration, run a fresh plan; it should show no changes.

What you need to know:

- **Existing inputs keep working.** `resource_group_name` is still accepted. The new `parent_id`
  input is the preferred alternative. Set exactly one of them.
- **Plan with refresh enabled.** Use Terraform's default refresh when planning the upgrade. Review
  the plan and stop if it shows an unexpected replacement of an existing resource.
- **Keep an `azurerm` provider block in the root module for the upgrade apply.** Terraform must be
  able to read the pre-migration state rows before the `moved` blocks convert them. The block can be
  removed afterwards.
- **Map the target AzAPI provider when it is an alias.** The module derives the deployment
  subscription from its AzAPI provider when `resource_group_name` is used, and scopes custom
  role-name lookups to the subscription in `parent_id`. Role names are looked up at that
  subscription; if a role name is not available there, pass its full role-definition ID. Map the
  caller's target alias to the module's default `azapi` provider. The retained `azurerm` provider is
  only for reading legacy state; do not pass it to the migrated module.

  ```terraform
  variable "target_subscription_id" {
    type = string
  }

  provider "azurerm" {
    features {}
  }

  provider "azapi" {
    alias           = "target"
    subscription_id = var.target_subscription_id
  }

  module "firewall_policy" {
    source = "./firewall-policy-module"

    name      = "example"
    location  = "eastus"
    parent_id = "/subscriptions/${var.target_subscription_id}/resourceGroups/example"

    providers = {
      azapi = azapi.target
    }
  }
  ```
- **The `resource` output changes shape.** It is now an object built from the `azapi_resource`:
  `id`, `name`, `location`, `tags`, `identity`, `parent_id`, `type`, `body`, `firewalls`,
  `child_policies` and `rule_collection_groups`. Other AzureRM attributes are read from
  `resource.body.properties`, for example `sku` becomes `body.properties.sku.tier` and
  `threat_intelligence_mode` becomes `body.properties.threatIntelMode`. `resource_id` is unchanged.
- **New outputs.** `name`, `location`, `firewalls`, `child_policies` and `rule_collection_groups`.
  `rule_collection_groups` comes from a live read, so a group created in the same apply appears on
  the next plan.
- **Minimum Terraform is now 1.9.** The AVM interfaces module used for locks, role assignments and
  diagnostic settings requires it.
- **New optional inputs.** `resource_types`, `ignore_body_changes`, `retry` and `timeouts`. Their
  defaults preserve the previous behaviour.
"Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>"
