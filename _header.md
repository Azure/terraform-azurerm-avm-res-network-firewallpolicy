# terraform-azurerm-avm-network-firewallpolicy

This is the module to create an Azure Firewall Policy

## Upgrading from 0.3.4

The root module requires Terraform 1.7 or later to remove the previous telemetry
objects from state without destroying them. Terraform may need to initialize the
previous `Azure/modtm` and `hashicorp/random` providers once more when upgrading
an existing state. The `rule_collection_groups` submodule requires Terraform
1.9 or later and enables telemetry by default; supply a `location` when
telemetry is enabled, or set `enable_telemetry = false` to omit it.

"Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>"
