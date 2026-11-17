terraform {
  # Terraform 1.11 supports AzAPI's write-only ignore_body_changes argument.
  required_version = ">= 1.11, < 2.0"

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
  }
}
