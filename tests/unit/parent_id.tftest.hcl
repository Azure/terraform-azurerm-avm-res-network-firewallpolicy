mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/example/providers/Microsoft.Network/firewallPolicies/firewall-policy-test"
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000001"
      tenant_id       = "00000000-0000-0000-0000-000000000002"
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000007"
            role_name = "Custom Firewall Operator"
          }
        ]
      }
    }
  }
}

mock_provider "azapi" {
  alias = "target"

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000005/resourceGroups/example/providers/Microsoft.Network/firewallPolicies/firewall-policy-test"
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000005"
      tenant_id       = "00000000-0000-0000-0000-000000000002"
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

mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location         = "eastus"
  name             = "firewall-policy-test"
  enable_telemetry = false
}

run "accepts_case_insensitive_resource_group_id" {
  command   = apply
  state_key = "case_insensitive_parent"

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourcegroups/example"
  }

  assert {
    condition     = azapi_resource.this.parent_id == var.parent_id
    error_message = "A valid Resource Group ID should be accepted regardless of segment casing."
  }
}

run "keeps_legacy_resource_group_name_in_provider_subscription" {
  command   = apply
  state_key = "legacy_resource_group_name"

  variables {
    resource_group_name = "legacy-rg"
  }

  assert {
    condition     = azapi_resource.this.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/legacy-rg"
    error_message = "The legacy resource_group_name input should continue to use the selected AzAPI provider subscription."
  }
}

run "uses_mapped_azapi_alias_subscription" {
  command   = apply
  state_key = "mapped_azapi_alias"

  providers = {
    azapi = azapi.target
  }

  variables {
    resource_group_name = "legacy-rg"
  }

  assert {
    condition     = azapi_resource.this.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000005/resourceGroups/legacy-rg"
    error_message = "The module should use the subscription from the AzAPI provider explicitly mapped by its caller."
  }
}

run "rejects_wrong_parent_resource_type" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Network/firewallPolicies/example"
  }

  expect_failures = [
    var.parent_id
  ]
}

run "rejects_child_resource_id_as_parent" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example/providers/Microsoft.Network/firewallPolicies/policy"
  }

  expect_failures = [
    var.parent_id
  ]
}

run "uses_parent_subscription_for_custom_role_name_lookup" {
  command   = apply
  state_key = "custom_role_parent_subscription"

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example"
    role_assignments = {
      custom = {
        role_definition_id_or_name = "Custom Firewall Operator"
        principal_id               = "00000000-0000-0000-0000-000000000004"
      }
      full_id = {
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000006"
        principal_id               = "00000000-0000-0000-0000-000000000004"
      }
    }

  }

  assert {
    condition     = local.firewall_policy_subscription_id == "00000000-0000-0000-0000-000000000003"
    error_message = "Role-definition name lookups must use the subscription containing the firewall policy."
  }

  assert {
    condition     = module.interfaces.role_assignments_azapi["custom"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000007"
    error_message = "A role name returned by the target subscription lookup should resolve to that subscription's role-definition ID."
  }

  assert {
    condition     = module.interfaces.role_assignments_azapi["full_id"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000006"
    error_message = "A fully qualified role-definition ID should pass through unchanged."
  }
}

run "creates_role_assignment_with_explicit_name" {
  command   = apply
  state_key = "role_assignment_name_lifecycle"

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example"
    role_assignments = {
      test = {
        name                       = "00000000-0000-0000-0000-000000000008"
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000006"
        principal_id               = "00000000-0000-0000-0000-000000000004"
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["test"].name == "00000000-0000-0000-0000-000000000008"
    error_message = "An explicitly supplied role-assignment GUID should be used at creation."
  }
}

run "ignores_role_assignment_name_changes_after_creation" {
  command   = plan
  state_key = "role_assignment_name_lifecycle"

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example"
    role_assignments = {
      test = {
        name                       = "00000000-0000-0000-0000-000000000009"
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000006"
        principal_id               = "00000000-0000-0000-0000-000000000004"
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["test"].name == "00000000-0000-0000-0000-000000000008"
    error_message = "Changing an adopted role-assignment name should not rename or replace the existing GUID."
  }
}
