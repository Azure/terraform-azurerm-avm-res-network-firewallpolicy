mock_provider "azapi" {}
mock_provider "azurerm" {}

variables {
  firewall_policy_rule_collection_group_firewall_policy_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-unit/providers/Microsoft.Network/firewallPolicies/fwp-unit"
  firewall_policy_rule_collection_group_name               = "rcg-unit"
  firewall_policy_rule_collection_group_priority           = 1000
  enable_telemetry                                         = false
  location                                                 = "eastus"
}

run "rule_with_fqdns_is_accepted" {
  command = plan

  variables {
    firewall_policy_rule_collection_group_application_rule_collection = [{
      action   = "Allow"
      name     = "app"
      priority = 1200
      rule = [{
        name              = "fqdn"
        source_addresses  = ["10.0.0.0/24"]
        destination_fqdns = ["example.com"]
        protocols         = [{ port = 443, type = "Https" }]
      }]
    }]
  }
}

run "rule_with_only_web_categories_is_accepted" {
  command = plan

  variables {
    firewall_policy_rule_collection_group_application_rule_collection = [{
      action   = "Deny"
      name     = "app"
      priority = 1200
      rule = [{
        name             = "web"
        source_addresses = ["10.0.0.0/24"]
        web_categories   = ["Gambling"]
        protocols        = [{ port = 443, type = "Https" }]
      }]
    }]
  }
}

run "rule_without_target_is_rejected" {
  command = plan

  variables {
    firewall_policy_rule_collection_group_application_rule_collection = [{
      action   = "Allow"
      name     = "app"
      priority = 1200
      rule = [{
        name                  = "specific-test"
        source_addresses      = ["10.0.0.0/24"]
        destination_addresses = ["90.10.132.194", "8.7.50.77"]
        protocols             = [{ port = 443, type = "Https" }]
      }]
    }]
  }

  expect_failures = [var.firewall_policy_rule_collection_group_application_rule_collection]
}

run "explicit_null_targets_are_rejected" {
  command = plan

  variables {
    firewall_policy_rule_collection_group_application_rule_collection = [{
      action   = "Allow"
      name     = "app"
      priority = 1200
      rule = [{
        name              = "nulls"
        source_addresses  = ["10.0.0.0/24"]
        destination_fqdns = null
        destination_urls  = null
        protocols         = [{ port = 443, type = "Https" }]
      }]
    }]
  }

  expect_failures = [var.firewall_policy_rule_collection_group_application_rule_collection]
}
