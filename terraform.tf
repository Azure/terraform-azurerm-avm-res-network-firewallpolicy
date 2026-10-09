terraform {
  # `Azure/avm-utl-interfaces/azure` 0.6.0 -- the AVM standard-interfaces composer this module now
  # uses for its lock, role-assignment and diagnostic-setting bodies -- declares
  # `required_version = "~> 1.9"`. Terraform resolves the INTERSECTION of every constraint in the
  # graph, so a root left at `~> 1.5` would simply fail to initialise against it. The floor moves
  # to 1.9 for that reason and no other.
  required_version = ">= 1.9, < 2.0"

  required_providers {
    # `avm-tf-migration` SKILL.md L92: the AzAPI target must pin `Azure/azapi ~> 2.12`. The
    # `terraform-azurerm-avm-ptn-alz-connectivity-virtual-wan` repository pins the same range, so
    # a consumer composing both gets one provider instance rather than a resolution conflict.
    #
    # ⚠️ `~> 2.12` admits 2.13.0, which is what a module-scoped `terraform init` resolves here
    # (this module ships no lock file). Every provider-source fact recorded in `locals.tf` and in
    # the comments below was read at tag **v2.13.0**.
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
