# TODO: insert outputs here.

output "resource" {
  value       = azurerm_firewall_policy.this
  description = <<-EOT
  "This output is for Firewall Policy resource. This is the default output for the module following AVM standards. Review the examples below for the correct output to use in your module."
  Examples: 
  - module.firewall_policy.resource.id
  - module.firewall_policy.resource.firewalls
  - module.firewall_policy.resource.child_policies
  - module.firewall_policy.resource.rule_collection_groups
  EOT
}
