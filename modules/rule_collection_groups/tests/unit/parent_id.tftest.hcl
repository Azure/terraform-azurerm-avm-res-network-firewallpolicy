mock_provider "azapi" {}

variables {
  firewall_policy_rule_collection_group_name     = "rule-collection-group-test"
  firewall_policy_rule_collection_group_priority = 100
}

run "accepts_case_insensitive_firewall_policy_id" {
  command   = apply
  state_key = "case_insensitive_firewall_policy_parent"

  variables {
    firewall_policy_rule_collection_group_firewall_policy_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourcegroups/example/providers/microsoft.network/firewallpolicies/policy"
  }

  assert {
    condition     = azapi_resource.this.parent_id == var.firewall_policy_rule_collection_group_firewall_policy_id
    error_message = "A valid Firewall Policy ID should be accepted regardless of segment casing."
  }
}

run "rejects_resource_group_as_firewall_policy_parent" {
  command = plan

  variables {
    firewall_policy_rule_collection_group_firewall_policy_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/example"
  }

  expect_failures = [
    var.firewall_policy_rule_collection_group_firewall_policy_id
  ]
}

run "rejects_wrong_firewall_policy_resource_type" {
  command = plan

  variables {
    firewall_policy_rule_collection_group_firewall_policy_id = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/example/providers/MicrosoftXNetwork/firewallPolicies/policy"
  }

  expect_failures = [
    var.firewall_policy_rule_collection_group_firewall_policy_id
  ]
}
