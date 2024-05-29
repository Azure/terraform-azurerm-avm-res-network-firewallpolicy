resource "azurerm_firewall_policy_rule_collection_group" "this" {
  firewall_policy_id = var.firewall_policy_rule_collection_group_firewall_policy_id
  name               = var.firewall_policy_rule_collection_group_name
  priority           = var.firewall_policy_rule_collection_group_priority

  dynamic "application_rule_collection" {
    for_each = var.firewall_policy_rule_collection_group_application_rule_collection == null ? [] : var.firewall_policy_rule_collection_group_application_rule_collection
    content {
      action   = application_rule_collection.value.action
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority

      dynamic "rule" {
        for_each = application_rule_collection.value.rule
        content {
          name                  = rule.value.name
          description           = rule.value.description
          destination_addresses = rule.value.destination_addresses
          destination_fqdn_tags = rule.value.destination_fqdn_tags
          destination_fqdns     = rule.value.destination_fqdns
          destination_urls      = rule.value.destination_urls
          source_addresses      = rule.value.source_addresses
          source_ip_groups      = rule.value.source_ip_groups
          terminate_tls         = rule.value.terminate_tls
          web_categories        = rule.value.web_categories

          dynamic "http_headers" {
            for_each = rule.value.http_headers == null ? [] : rule.value.http_headers
            content {
              name  = http_headers.value.name
              value = http_headers.value.value
            }
          }
          dynamic "protocols" {
            for_each = rule.value.protocols == null ? [] : rule.value.protocols
            content {
              port = protocols.value.port
              type = protocols.value.type
            }
          }
        }
      }
    }
  }
  dynamic "nat_rule_collection" {
    for_each = var.firewall_policy_rule_collection_group_nat_rule_collection == null ? [] : var.firewall_policy_rule_collection_group_nat_rule_collection
    content {
      action   = nat_rule_collection.value.action
      name     = nat_rule_collection.value.name
      priority = nat_rule_collection.value.priority

      dynamic "rule" {
        for_each = nat_rule_collection.value.rule
        content {
          name                = rule.value.name
          protocols           = rule.value.protocols
          translated_port     = rule.value.translated_port
          destination_address = rule.value.destination_address
          destination_ports   = rule.value.destination_ports
          source_addresses    = rule.value.source_addresses
          source_ip_groups    = rule.value.source_ip_groups
          translated_address  = rule.value.translated_address
          translated_fqdn     = rule.value.translated_fqdn
        }
      }
    }
  }
  dynamic "network_rule_collection" {
    for_each = var.firewall_policy_rule_collection_group_network_rule_collection == null ? [] : var.firewall_policy_rule_collection_group_network_rule_collection
    content {
      action   = network_rule_collection.value.action
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority

      dynamic "rule" {
        for_each = network_rule_collection.value.rule
        content {
          destination_ports     = rule.value.destination_ports
          name                  = rule.value.name
          protocols             = rule.value.protocols
          destination_addresses = rule.value.destination_addresses
          destination_fqdns     = rule.value.destination_fqdns
          destination_ip_groups = rule.value.destination_ip_groups
          source_addresses      = rule.value.source_addresses
          source_ip_groups      = rule.value.source_ip_groups
        }
      }
    }
  }
  dynamic "timeouts" {
    for_each = var.firewall_policy_rule_collection_group_timeouts == null ? [] : [var.firewall_policy_rule_collection_group_timeouts]
    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}