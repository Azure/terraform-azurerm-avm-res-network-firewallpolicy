mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/example/providers/Microsoft.Network/firewallPolicies/firewall-policy-test"
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000001"
      tenant_id                = "00000000-0000-0000-0000-000000000002"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000001"
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
  providers = {
    azapi  = azapi
    random = random
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
  providers = {
    azapi  = azapi
    random = random
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
  providers = {
    azapi  = azapi
    random = random
  }
}

run "rejects_child_resource_id_as_parent" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example/providers/Microsoft.Network/firewallPolicies/policy"
  }

  expect_failures = [
    var.parent_id
  ]
  providers = {
    azapi  = azapi
    random = random
  }
}

run "resolves_custom_role_name_from_parent_lookup" {
  command   = apply
  state_key = "custom_role_parent_lookup"

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
    condition     = module.interfaces.role_assignments_azapi["custom"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000007"
    error_message = "A role name returned by the parent lookup should resolve to that role-definition ID."
  }

  assert {
    condition     = module.interfaces.role_assignments_azapi["full_id"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000006"
    error_message = "A fully qualified role-definition ID should pass through unchanged."
  }
  providers = {
    azapi  = azapi
    random = random
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
  providers = {
    azapi  = azapi
    random = random
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
  providers = {
    azapi  = azapi
    random = random
  }
}

run "sends_service_principal_type_when_skip_check_is_true" {
  command   = apply
  state_key = "principal_type_fallback"

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example"
    role_assignments = {
      skip = {
        role_definition_id_or_name       = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000006"
        principal_id                     = "00000000-0000-0000-0000-000000000004"
        skip_service_principal_aad_check = true
      }
      explicit = {
        role_definition_id_or_name       = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000006"
        principal_id                     = "00000000-0000-0000-0000-000000000004"
        skip_service_principal_aad_check = true
        principal_type                   = "Group"
      }
      default = {
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000006"
        principal_id               = "00000000-0000-0000-0000-000000000004"
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["skip"].body.properties.principalType == "ServicePrincipal"
    error_message = "skip_service_principal_aad_check = true must send principalType ServicePrincipal when principal_type is unset."
  }

  assert {
    condition     = azapi_resource.role_assignments["explicit"].body.properties.principalType == "Group"
    error_message = "An explicit principal_type must win over skip_service_principal_aad_check."
  }

  assert {
    condition     = azapi_resource.role_assignments["default"].body.properties.principalType == null
    error_message = "principalType must stay unset when neither the flag nor principal_type is set."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "derives_distinct_role_assignment_names_from_principal" {
  command   = apply
  state_key = "derived_role_assignment_names"

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example"
    role_assignments = {
      first = {
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000006"
        principal_id               = "00000000-0000-0000-0000-000000000004"
      }
      second = {
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000006"
        principal_id               = "00000000-0000-0000-0000-00000000000a"
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["first"].name != azapi_resource.role_assignments["second"].name
    error_message = "Assignments with different principals must get different derived names."
  }

  assert {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$", azapi_resource.role_assignments["first"].name))
    error_message = "A derived role-assignment name must be a lowercase UUIDv5."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "retries_principal_not_found_on_role_assignments_by_default" {
  command   = apply
  state_key = "default_retry"

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example"
    role_assignments = {
      test = {
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000006"
        principal_id               = "00000000-0000-0000-0000-000000000004"
      }
    }
  }

  assert {
    condition     = contains(azapi_resource.role_assignments["test"].retry.error_message_regex, "PrincipalNotFound") && contains(azapi_resource.role_assignments["test"].retry.error_message_regex, "409 Conflict")
    error_message = "The default retry must cover PrincipalNotFound and 409 Conflict on role assignments, as AzureRM did."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "forwards_custom_retry_to_role_assignments" {
  command   = apply
  state_key = "custom_retry"

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000003/resourceGroups/example"
    retry = {
      error_message_regex = ["CustomTransient"]
      interval_seconds    = 7
    }
    role_assignments = {
      test = {
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000003/providers/Microsoft.Authorization/roleDefinitions/00000000-0000-0000-0000-000000000006"
        principal_id               = "00000000-0000-0000-0000-000000000004"
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignments["test"].retry.error_message_regex == tolist(["CustomTransient"]) && azapi_resource.role_assignments["test"].retry.interval_seconds == 7
    error_message = "A consumer retry override must reach the role assignment."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}
