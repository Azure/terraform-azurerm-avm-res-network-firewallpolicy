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
}

mock_provider "random" {}

variables {
  enable_telemetry = false
  location         = "eastus"
  name             = "firewall-policy-test"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/example"
}

run "missing_back_references_remain_empty_lists" {
  command   = apply
  state_key = "missing_back_references"

  override_data {
    target = data.azapi_resource.this
    values = {
      output = {}
    }
  }

  assert {
    condition     = length(output.child_policies) == 0 && output.resource.child_policies == output.child_policies
    error_message = "Missing child policies must remain empty lists in both output interfaces."
  }

  assert {
    condition     = length(output.firewalls) == 0 && output.resource.firewalls == output.firewalls
    error_message = "Missing firewalls must remain empty lists in both output interfaces."
  }

  assert {
    condition     = length(output.rule_collection_groups) == 0 && output.resource.rule_collection_groups == output.rule_collection_groups
    error_message = "Missing rule collection groups must remain empty lists in both output interfaces."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "null_back_references_remain_empty_lists" {
  command   = apply
  state_key = "null_back_references"

  override_data {
    target = data.azapi_resource.this
    values = {
      output = {
        child_policies         = null
        firewalls              = null
        rule_collection_groups = null
      }
    }
  }

  assert {
    condition     = length(output.child_policies) == 0 && output.resource.child_policies == output.child_policies
    error_message = "Null child policies must remain empty lists in both output interfaces."
  }

  assert {
    condition     = length(output.firewalls) == 0 && output.resource.firewalls == output.firewalls
    error_message = "Null firewalls must remain empty lists in both output interfaces."
  }

  assert {
    condition     = length(output.rule_collection_groups) == 0 && output.resource.rule_collection_groups == output.rule_collection_groups
    error_message = "Null rule collection groups must remain empty lists in both output interfaces."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "populated_back_references_retain_resource_ids" {
  command   = apply
  state_key = "populated_back_references"

  override_data {
    target = data.azapi_resource.this
    values = {
      output = {
        child_policies = [
          "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/example/providers/Microsoft.Network/firewallPolicies/child-policy-one",
          "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/example/providers/Microsoft.Network/firewallPolicies/child-policy-two"
        ]
        firewalls = [
          "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/example/providers/Microsoft.Network/azureFirewalls/firewall"
        ]
        rule_collection_groups = [
          "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/example/providers/Microsoft.Network/firewallPolicies/firewall-policy-test/ruleCollectionGroups/group"
        ]
      }
    }
  }

  assert {
    condition = output.child_policies == tolist([
      "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/example/providers/Microsoft.Network/firewallPolicies/child-policy-one",
      "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/example/providers/Microsoft.Network/firewallPolicies/child-policy-two"
    ]) && output.resource.child_policies == output.child_policies
    error_message = "Both output interfaces must preserve the child policy IDs and their order."
  }

  assert {
    condition = output.firewalls == tolist([
      "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/example/providers/Microsoft.Network/azureFirewalls/firewall"
    ]) && output.resource.firewalls == output.firewalls
    error_message = "Both output interfaces must preserve the firewall IDs."
  }

  assert {
    condition = output.rule_collection_groups == tolist([
      "/subscriptions/00000000-0000-0000-0000-000000000001/resourceGroups/example/providers/Microsoft.Network/firewallPolicies/firewall-policy-test/ruleCollectionGroups/group"
    ]) && output.resource.rule_collection_groups == output.rule_collection_groups
    error_message = "Both output interfaces must preserve the rule collection group IDs."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}
