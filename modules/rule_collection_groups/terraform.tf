terraform {
  # Terraform 1.11 supports AzAPI's write-only ignore_body_changes argument.
  required_version = ">= 1.11, < 2.0"

  required_providers {
    # ⚠️ `hashicorp/azurerm` IS GONE FROM THIS SUBMODULE. It is not merely
    # unused: leaving the requirement in place would keep forcing consumers to
    # configure and pass an azurerm provider for a module that never calls it.
    #
    # `~> 2.12` matches the parent module and the `alz-connectivity-virtual-wan`
    # pattern module that consumes it. The `moved` state mover this migration
    # depends on lives in `azapi_resource` and the behaviour relied on here was
    # read from v2.13.0, which `~> 2.12` resolves to.
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }
}
