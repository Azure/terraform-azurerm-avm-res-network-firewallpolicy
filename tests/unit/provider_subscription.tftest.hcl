mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000005/resourceGroups/example/providers/Microsoft.Network/firewallPolicies/firewall-policy-test"
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000005"
      tenant_id                = "00000000-0000-0000-0000-000000000002"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000005"
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = []
      }
    }
  }
}

mock_provider "random" {}

variables {
  location         = "eastus"
  name             = "firewall-policy-test"
  enable_telemetry = false
}

run "uses_subscription_of_the_azapi_provider_for_legacy_resource_group_name" {
  command   = apply
  state_key = "provider_subscription"

  variables {
    resource_group_name = "legacy-rg"
  }

  assert {
    condition     = azapi_resource.this.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000005/resourceGroups/legacy-rg"
    error_message = "The module should use the subscription of the AzAPI provider its caller supplies."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "parent_id_is_known_when_the_policy_is_first_planned" {
  command   = plan
  state_key = "first_plan"

  variables {
    resource_group_name = "legacy-rg"
  }

  assert {
    condition     = azapi_resource.this.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000005/resourceGroups/legacy-rg"
    error_message = "parent_id must be known at plan time on the first plan, including the plan that migrates an AzureRM policy, or the adopted policy is replaced."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}
