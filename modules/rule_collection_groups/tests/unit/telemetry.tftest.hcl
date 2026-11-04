mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {}

variables {
  firewall_policy_rule_collection_group_firewall_policy_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/firewallPolicies/test"
  firewall_policy_rule_collection_group_name               = "test"
  firewall_policy_rule_collection_group_priority           = 100
}

run "telemetry_disabled_without_location" {
  command = plan

  variables {
    enable_telemetry = false
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 0
    error_message = "Telemetry must be absent when disabled."
  }
}

run "telemetry_disabled_with_null_location" {
  command = plan

  variables {
    enable_telemetry = false
    location         = null
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 0
    error_message = "An explicit null location must be accepted when telemetry is disabled."
  }
}

run "telemetry_enabled_requires_location" {
  command = plan

  expect_failures = [var.location]
}

run "telemetry_enabled_with_location" {
  command = plan

  variables {
    location = "eastus"
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 1
    error_message = "Telemetry must be present when enabled with a location."
  }
}
