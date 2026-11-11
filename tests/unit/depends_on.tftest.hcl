mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000006/resourceGroups/legacy-rg/providers/Microsoft.Network/firewallPolicies/firewall-policy-test"
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000006"
      tenant_id                = "00000000-0000-0000-0000-000000000002"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000006"
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

run "create" {
  command   = apply
  state_key = "caller_depends_on"

  module {
    source = "./tests/unit/fixtures/dep"
  }

  variables {
    upstream_input = "before"
  }

  assert {
    condition     = output.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000006/resourceGroups/legacy-rg"
    error_message = "The policy should be created in the provider subscription."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "change_upstream" {
  command   = plan
  state_key = "caller_depends_on"

  module {
    source = "./tests/unit/fixtures/dep"
  }

  variables {
    upstream_input = "after"
  }

  assert {
    condition     = output.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000006/resourceGroups/legacy-rg"
    error_message = "A pending change on the caller's depends_on must not make parent_id unknown, which would replace the policy."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}
