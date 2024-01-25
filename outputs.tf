# TODO: insert outputs here.
output "id" {
  description = "The ID of the Firewall Policy."
  value       = azurerm_firewall_policy.this
}

output "name" {
  description = "The name of the Firewall Policy."
  value       = azurerm_firewall_policy.this
}
