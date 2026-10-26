mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000001"
    }
  }
}

mock_provider "modtm" {}

mock_provider "random" {
  mock_resource "random_uuid" {
    defaults = {
      result = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
    }
  }
}

# Offline role-assignment replacement checks. The plan runs use the real AzAPI provider so that
# `replace_triggers_refs` is evaluated by the provider itself. Refresh is disabled, the endpoints
# are pinned to unreachable loopback addresses and no Azure authentication is used. State comes
# from the mocked apply runs. Run with: terraform test -test-directory=tests/offline
provider "azapi" {
  alias                      = "offline"
  subscription_id            = "00000000-0000-0000-0000-000000000000"
  tenant_id                  = "00000000-0000-0000-0000-000000000001"
  client_id                  = "00000000-0000-0000-0000-000000000002"
  client_secret              = "not-a-real-secret"
  use_cli                    = false
  use_msi                    = false
  use_oidc                   = false
  use_aks_workload_identity  = false
  skip_provider_registration = true
  enable_preflight           = false
  ignore_no_op_changes       = false
  disable_instance_discovery = true
  endpoint = [{
    active_directory_authority_host = "https://127.0.0.1:1/"
    resource_manager_endpoint       = "https://127.0.0.1:1/"
    resource_manager_audience       = "https://127.0.0.1:1/"
  }]
}

override_resource {
  target = azapi_resource.this
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/firewallPolicies/fwp-review"
  }
}

override_data {
  target = data.azapi_resource.this
  values = {
    output = {
      child_policies         = []
      firewalls              = []
      rule_collection_groups = []
    }
  }
}

override_data {
  target = module.interfaces.data.azapi_resource_list.role_definitions[0]
  values = {
    output = {
      results = [{
        id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        role_name = "Reader"
      }]
    }
  }
}

variables {
  enable_telemetry = false
  name             = "fwp-review"
  location         = "eastus"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  role_assignments = {
    reader = {
      name                       = "11111111-1111-4111-8111-111111111111"
      principal_id               = "22222222-2222-4222-8222-222222222222"
      role_definition_id_or_name = "Reader"
    }
  }
}

run "seed_existing_assignment" {
  command = apply
  providers = {
    azapi  = azapi
    modtm  = modtm
    random = random
  }
}

run "real_provider_preserves_existing_guid" {
  command = plan
  providers = {
    azapi  = azapi.offline
    modtm  = modtm
    random = random
  }
  plan_options {
    refresh = false
  }
  variables {
    role_assignments = {
      reader = {
        principal_id               = "22222222-2222-4222-8222-222222222222"
        role_definition_id_or_name = "Reader"
      }
    }
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].name == "11111111-1111-4111-8111-111111111111"
    error_message = "An existing assignment must retain its GUID when the module derives a different name."
  }
}

run "real_provider_replaces_principal_edit_with_fresh_guid" {
  command = plan
  providers = {
    azapi  = azapi.offline
    modtm  = modtm
    random = random
  }
  plan_options {
    refresh = false
  }
  variables {
    role_assignments = {
      reader = {
        principal_id               = "33333333-3333-4333-8333-333333333333"
        role_definition_id_or_name = "Reader"
      }
    }
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].name != "11111111-1111-4111-8111-111111111111" && azapi_resource.role_assignments["reader"].body.properties.principalId == "33333333-3333-4333-8333-333333333333"
    error_message = "A principal edit must replace the assignment with a new GUID, not reuse the adopted one."
  }
}

run "real_provider_replaces_role_edit_with_fresh_guid" {
  command = plan
  providers = {
    azapi  = azapi.offline
    modtm  = modtm
    random = random
  }
  plan_options {
    refresh = false
  }
  variables {
    role_assignments = {
      reader = {
        principal_id               = "22222222-2222-4222-8222-222222222222"
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
      }
    }
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].name != "11111111-1111-4111-8111-111111111111" && endswith(azapi_resource.role_assignments["reader"].body.properties.roleDefinitionId, "b24988ac-6180-42a0-ab88-20f7382dd24c")
    error_message = "A role edit must replace the assignment with a new GUID, not reuse the adopted one."
  }
}

run "real_provider_replaces_delegated_identity_edit_with_fresh_guid" {
  command = plan
  providers = {
    azapi  = azapi.offline
    modtm  = modtm
    random = random
  }
  plan_options {
    refresh = false
  }
  variables {
    role_assignments = {
      reader = {
        principal_id                           = "22222222-2222-4222-8222-222222222222"
        role_definition_id_or_name             = "Reader"
        delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/delegated"
      }
    }
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].name != "11111111-1111-4111-8111-111111111111"
    error_message = "A delegated-identity edit must replace the assignment with a new GUID, not reuse the adopted one."
  }
}

run "real_provider_replaces_immutable_and_mutable_edit_with_fresh_guid" {
  command = plan
  providers = {
    azapi  = azapi.offline
    modtm  = modtm
    random = random
  }
  plan_options {
    refresh = false
  }
  variables {
    role_assignments = {
      reader = {
        principal_id               = "33333333-3333-4333-8333-333333333333"
        role_definition_id_or_name = "Reader"
        description                = "A mutable edit must not hide the immutable one."
      }
    }
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].name != "11111111-1111-4111-8111-111111111111" && azapi_resource.role_assignments["reader"].body.properties.description == "A mutable edit must not hide the immutable one."
    error_message = "An immutable edit together with a mutable edit must still replace the assignment with a new GUID."
  }
}

run "real_provider_allows_description_edit" {
  command = plan
  providers = {
    azapi  = azapi.offline
    modtm  = modtm
    random = random
  }
  plan_options {
    refresh = false
  }
  variables {
    role_assignments = {
      reader = {
        principal_id               = "22222222-2222-4222-8222-222222222222"
        role_definition_id_or_name = "Reader"
        description                = "Updated description"
      }
    }
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].body.properties.description == "Updated description" && azapi_resource.role_assignments["reader"].name == "11111111-1111-4111-8111-111111111111"
    error_message = "Mutable changes must remain allowed without changing the assignment GUID."
  }
}

run "real_provider_allows_condition_edit" {
  command = plan
  providers = {
    azapi  = azapi.offline
    modtm  = modtm
    random = random
  }
  plan_options {
    refresh = false
  }
  variables {
    role_assignments = {
      reader = {
        principal_id               = "22222222-2222-4222-8222-222222222222"
        role_definition_id_or_name = "Reader"
        condition                  = "(!(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write'}))"
        condition_version          = "2.0"
      }
    }
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].body.properties.conditionVersion == "2.0" && azapi_resource.role_assignments["reader"].name == "11111111-1111-4111-8111-111111111111"
    error_message = "Mutable condition changes must keep the assignment GUID."
  }
}

run "real_provider_accepts_equivalent_role_id_casing" {
  command = plan
  providers = {
    azapi  = azapi.offline
    modtm  = modtm
    random = random
  }
  plan_options {
    refresh = false
  }
  variables {
    role_assignments = {
      reader = {
        principal_id               = "22222222-2222-4222-8222-222222222222"
        role_definition_id_or_name = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/MICROSOFT.AUTHORIZATION/roleDefinitions/ACDD72A7-3385-48EF-BD42-F606FBA81AE7"
      }
    }
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].name == "11111111-1111-4111-8111-111111111111"
    error_message = "A change in casing alone must not replace the assignment."
  }
}

run "remove_old_assignment" {
  command = apply
  providers = {
    azapi  = azapi
    modtm  = modtm
    random = random
  }
  variables {
    role_assignments = {}
  }
}

run "recreate_with_new_principal_and_guid" {
  command = apply
  providers = {
    azapi  = azapi
    modtm  = modtm
    random = random
  }
  variables {
    role_assignments = {
      reader = {
        principal_id               = "33333333-3333-4333-8333-333333333333"
        role_definition_id_or_name = "Reader"
      }
    }
  }
  assert {
    condition     = azapi_resource.role_assignments["reader"].name != "11111111-1111-4111-8111-111111111111" && azapi_resource.role_assignments["reader"].body.properties.principalId == "33333333-3333-4333-8333-333333333333"
    error_message = "Removal and recreation must allow a new principal with a fresh GUID."
  }
}

run "seed_delegated_identity" {
  command = apply
  providers = {
    azapi  = azapi
    modtm  = modtm
    random = random
  }
  variables {
    role_assignments = {
      delegated = {
        principal_id                           = "22222222-2222-4222-8222-222222222222"
        role_definition_id_or_name             = "Reader"
        delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/delegated"
      }
    }
  }
}

run "real_provider_replaces_delegated_identity_removal_with_fresh_guid" {
  command = plan
  providers = {
    azapi  = azapi.offline
    modtm  = modtm
    random = random
  }
  plan_options {
    refresh = false
  }
  variables {
    role_assignments = {
      delegated = {
        principal_id               = "22222222-2222-4222-8222-222222222222"
        role_definition_id_or_name = "Reader"
      }
    }
  }
  assert {
    condition = azapi_resource.role_assignments["delegated"].name != uuidv5("url", join("|", [
      lower(azapi_resource.this.id),
      "22222222-2222-4222-8222-222222222222",
      "/subscriptions/00000000-0000-0000-0000-000000000000/providers/microsoft.authorization/roledefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7",
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/rg-test/providers/microsoft.managedidentity/userassignedidentities/delegated",
    ]))
    error_message = "Removing a delegated identity must replace the assignment with a new GUID."
  }
}
