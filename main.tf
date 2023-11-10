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
  threat_intelligence_allowlist {
    fqdns        = var.threat_intel_fqdn_allowlist
    ip_addresses = var.threat_intel_ip_allowlist
  }
  tags = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "firewall_policy_collection_group" {
  for_each           = each.value.rule_collection_group
  name               = coalesce(var.fw_policy_rcg_name, "rule-collection-group-${var.fw_policy_name}")
  firewall_policy_id = azurerm_firewall_policy.firewall_policy.id
  priority           = var.app_rule_collection_priority

  application_rule_collection {
    name     = var.app_rule_collection_name
    priority = var_app_rule_collection_priority
    action   = var_app_rule_collection_action
    dynamic "rule" {
      for_each = each.value.app_rule.name
      content {
        name = app_rule.value.name
        protocols {
          type = var.app_rule.protocols.type
          port = var.app_rule.protocols.port
        }
      }
    }
  }

  network_rule_collection {
    name     = var_net_rule_collection_name
    priority = var_net_rule_collection_priority
    action   = var_net_rule_collection_action
    dynamic "rule" {
      for_each = each.value.net_rule.name
      content {
        name              = net_rule.value.name
        protocols         = var.net_rule.protocols
        destination_ports = var.net_rule.destination_ports
      }
    }
  }

  nat_rule_collection {
    name     = var.nat_rule_collection_name
    priority = var_nat_rule_collection_priority
    action   = var_nat_rule_collection_action
    dynamic "rule" {
      for_each = each.value.nat_rule.name
      content {
        name            = nat_rule.value.name
        protocols       = var.nat_rule.protocols
        translated_port = var.nat_rule.translated_port
      }
    }
  }
}

resource "azurerm_management_lock" "this" {
  count      = var.lock.kind != "None" ? 1 : 0
  name       = coalesce(var.lock.name, "lock-${var.fw_policy_name}")
  scope      = azurerm_virtual_network.vnet.id
  lock_level = var.lock.kind
}

# Assigning Roles to the Virtual Network based on the provided configurations.
resource "azurerm_role_assignment" "this" {
  for_each                               = var.role_assignments
  scope                                  = azurerm_virtual_network.vnet.id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  principal_id                           = each.value.principal_id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
}
