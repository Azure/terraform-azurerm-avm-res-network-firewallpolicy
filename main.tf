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