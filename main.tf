# TODO: insert resources here.
// Create Azure Firewall Policy

resource "azurerm_firewall_policy" "firewall_policy" {
  name                = var.fw_policy_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  dns {
    proxy_enabled = var.proxy_enabled
    servers       = var.dns_servers
  }
  threat_intelligence_mode = var.threat_intel_mode
  tags                     = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "firewall_policy_collection_group" {
  for_each           = var.rule_collection_group
  name               = coalesce(each.value.name, "rule-collection-group-${var.fw_policy_name}")
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = each.value.priority

  application_rule_collection {
    name     = var.app_rule_collection_name
    priority = var.app_rule_collection_priority
    action   = var.app_rule_collection_action
    dynamic "rule" {
      for_each = var.app_rule
      content {
        name = coalesce(each.value.app_rule.name, "app-rule-${var.app_rule_collection_name}")
        protocols {
          type = each.value.protocols.type
          port = each.value.protocols.port
        }
      }
    }
  }

  network_rule_collection {
    name     = var.net_rule_collection_name
    priority = var.net_rule_collection_priority
    action   = var.net_rule_collection_action
    dynamic "rule" {
      for_each = var.net_rule
      content {
        name              = coalesce(each.value.net_rule.name, "net-rule-${var.net_rule_collection_name}")
        protocols         = each.value.net_rule.protocols
        destination_ports = each.value.net_rule.destination_ports
      }
    }
  }

  nat_rule_collection {
    name     = var.nat_rule_collection_name
    priority = var.nat_rule_collection_priority
    action   = var.nat_rule_collection_action
    dynamic "rule" {
      for_each = var.nat_rule
      content {
        name            = coalesce(each.value.nat_rule.name, "nat-rule-${var.nat_rule_collection_name}")
        protocols       = each.value.nat_rule.protocols
        translated_port = each.value.nat_rule.translated_port
      }
    }
  }
}

resource "azurerm_management_lock" "this" {
  count      = var.lock.kind != "None" ? 1 : 0
  name       = coalesce(var.lock.name, "lock-${var.fw_policy_name}")
  scope      = azurerm_firewall_policy.firewall_policy.id
  lock_level = var.lock.kind
}

# Assigning Roles to the Virtual Network based on the provided configurations.
resource "azurerm_role_assignment" "this" {
  for_each                               = var.role_assignments
  scope                                  = azurerm_firewall_policy.firewall_policy.id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  principal_id                           = each.value.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
}
