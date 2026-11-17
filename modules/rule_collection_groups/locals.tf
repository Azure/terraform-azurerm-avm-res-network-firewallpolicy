# =============================================================================
# REQUEST BODY for the AzAPI migration of
# `azurerm_firewall_policy_rule_collection_group`.
#
# THE RULE THIS FILE FOLLOWS is the same one the parent module follows: every
# member is here because `hashicorp/azurerm` v4.81.0 put it on the wire, shaped
# and conditioned the way that provider shaped and conditioned it. The source is
# `internal/services/network/firewall_policy_rule_collection_group_resource.go`
# at v4.81.0, cited as "RCG L<n>"; `Create` and `Update` are one function
# (RCG L462) that builds the body from scratch and PUTs it whole.
#
# Member names come from the ARM type set --
# bicep-types-az `network/microsoft.network/2025-07-01`, nodes #1678
# `FirewallPolicyFilterRuleCollection`, #1728 `FirewallPolicyNatRuleCollection`,
# #1684 `ApplicationRule`, #1712 `NetworkRule`, #1700 `NatRule` -- not from
# memory, and NOT from the Go SDK's field names, which differ in case
# (`TargetURLs` is `targetUrls`, `TerminateTLS` is `terminateTLS`).
#
# 🔴 THE TWO DISCRIMINATORS ARE MANDATORY. `FirewallPolicyRuleCollection`
# discriminates on `ruleCollectionType` and `FirewallPolicyRule` on `ruleType`.
# The Go SDK emitted both automatically during marshalling, so they never
# appear in AzureRM's expander source; a hand-built AzAPI body has to write
# them explicitly or ARM cannot type the object at all.
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # 🔴 ORDER IS PART OF THE CONTRACT, AND IT IS NOT THE ORDER OF THE VARIABLE
  # DECLARATIONS.
  #
  # RCG L497-L505 appends the three collection kinds into ONE
  # `properties.ruleCollections` array in a fixed sequence:
  #
  #     rulesCollections = append(..., expand...Application(...)...)   // L497
  #     rulesCollections = append(..., expand...Network(...)...)       // L498
  #     natRules, err := expand...Nat(...)                             // L500
  #     rulesCollections = append(..., natRules...)                    // L505
  #
  # APPLICATION, then NETWORK, then NAT. `main.tf` in the AzureRM era declared
  # its `dynamic` blocks application / nat / network, which is a red herring --
  # HCL block order does not reach the wire; the Go append order does.
  #
  # `ruleCollections` is a JSON ARRAY, so a different order is a different
  # value. Get it wrong and every adopted rule collection group plans an
  # in-place update that rewrites the whole array.
  #
  # ⚠️ ORDER IS NOT PRIORITY. `priority` on each collection is what Azure
  # evaluates by; the array order is merely what the previous provider sent and
  # what the migrated state therefore holds. Both must be preserved, for
  # different reasons.
  # ---------------------------------------------------------------------------
  rule_collection_group_body = {
    properties = {
      priority = var.firewall_policy_rule_collection_group_priority
      ruleCollections = concat(
        local.rule_collections_application,
        local.rule_collections_network,
        local.rule_collections_nat,
      )
    }
  }

  # ---------------------------------------------------------------------------
  # APPLICATION RULE COLLECTIONS. RCG L597 -> `expandFirewallPolicyFilterRuleCollection`
  # (L626) with `expandFirewallPolicyRuleApplication` (L643).
  #
  # Collection level: `action.type`, `name` and `priority` are all unconditional
  # `pointer.To(...)` of required schema fields, and `rules` comes from
  # `make([]T, 0, ...)` so it is `[]` rather than null for a collection with no
  # rules.
  #
  # 🔴 RULE LEVEL, THE ONE ASYMMETRY WORTH READING TWICE. Two members are built
  # as `var xs []T` and then handed over as `&xs`:
  #
  #     var protocols []FirewallPolicyRuleApplicationProtocol   // L646
  #     var httpHeader []FirewallPolicyHTTPHeaderToInsert       // L655
  #
  # A nil Go slice behind a NON-NIL pointer marshals to JSON `null`, and
  # `omitempty` does not fire because the POINTER is not empty. So AzureRM sent
  # `"protocols": null` and `"httpHeadersToInsert": null` for a rule that
  # declared neither. Every other list on the rule goes through
  # `utils.ExpandStringSlice`, which returns a pointer to `make([]string, 0)`
  # and therefore sends `[]`. Both behaviours are reproduced literally: `null`
  # for those two, `[]` for the rest. `ignore_null_property = true` on the
  # resource turns the nulls back into absent members, which is what the JSON
  # `null` amounted to for an optional ARM member.
  #
  # `description` and `terminateTLS` are unconditional `pointer.To` of schema
  # values, so an unset `description` sent `""` and an unset `terminate_tls`
  # sent `false` -- not absent.
  # ---------------------------------------------------------------------------
  rule_collections_application = [
    for collection in coalesce(var.firewall_policy_rule_collection_group_application_rule_collection, []) : {
      ruleCollectionType = "FirewallPolicyFilterRuleCollection"
      name               = collection.name
      priority           = collection.priority
      action = {
        type = collection.action
      }
      rules = [
        for rule in collection.rule : {
          ruleType    = "ApplicationRule"
          name        = rule.name
          description = rule.description == null ? "" : rule.description
          protocols = rule.protocols == null ? null : (length(rule.protocols) == 0 ? null : [
            for protocol in rule.protocols : {
              protocolType = protocol.type
              port         = protocol.port
            }
          ])
          httpHeadersToInsert = rule.http_headers == null ? null : (length(rule.http_headers) == 0 ? null : [
            for header in rule.http_headers : {
              headerName  = header.name
              headerValue = header.value
            }
          ])
          sourceAddresses      = coalesce(rule.source_addresses, [])
          sourceIpGroups       = coalesce(rule.source_ip_groups, [])
          destinationAddresses = coalesce(rule.destination_addresses, [])
          targetFqdns          = coalesce(rule.destination_fqdns, [])
          targetUrls           = coalesce(rule.destination_urls, [])
          fqdnTags             = coalesce(rule.destination_fqdn_tags, [])
          terminateTLS         = rule.terminate_tls == null ? false : rule.terminate_tls
          webCategories        = coalesce(rule.web_categories, [])
        }
      ]
    }
  ]

  # ---------------------------------------------------------------------------
  # NETWORK RULE COLLECTIONS. RCG L601 -> the same filter-collection expander
  # with `expandFirewallPolicyRuleNetwork` (L684).
  #
  # Same `var protocols []T` -> `&protocols` pattern as application rules, on
  # `ipProtocols` this time (L687). The module's `protocols` member is a
  # REQUIRED `list(string)`, so the null branch is unreachable through the
  # public interface -- it is written anyway because the parity rule is "what
  # the provider did", not "what the provider did on the paths we expect".
  #
  # Note the AzureRM attribute named `destination_fqdns` maps to ARM's
  # `destinationFqdns` here but to `targetFqdns` on an application rule. The
  # two really are different members of different types.
  # ---------------------------------------------------------------------------
  rule_collections_network = [
    for collection in coalesce(var.firewall_policy_rule_collection_group_network_rule_collection, []) : {
      ruleCollectionType = "FirewallPolicyFilterRuleCollection"
      name               = collection.name
      priority           = collection.priority
      action = {
        type = collection.action
      }
      rules = [
        for rule in collection.rule : {
          ruleType             = "NetworkRule"
          name                 = rule.name
          description          = rule.description == null ? "" : rule.description
          ipProtocols          = length(rule.protocols) > 0 ? rule.protocols : null
          sourceAddresses      = coalesce(rule.source_addresses, [])
          sourceIpGroups       = coalesce(rule.source_ip_groups, [])
          destinationAddresses = coalesce(rule.destination_addresses, [])
          destinationIpGroups  = coalesce(rule.destination_ip_groups, [])
          destinationFqdns     = coalesce(rule.destination_fqdns, [])
          destinationPorts     = coalesce(rule.destination_ports, [])
        }
      ]
    }
  ]

  # ---------------------------------------------------------------------------
  # NAT RULE COLLECTIONS. RCG L605 -> `expandFirewallPolicyRuleCollectionNat`
  # with `expandFirewallPolicyRuleNat` (L708). Three oddities, all real:
  #
  # 🔴 1. `translatedPort` IS A STRING ON THE WIRE. RCG L739:
  #       `TranslatedPort: pointer.To(strconv.Itoa(condition["translated_port"].(int)))`.
  #       The module's variable is a `number`, the ARM member (#1700
  #       `translatedPort`) is a string, and `tostring()` is what bridges them.
  #       Emitting a JSON number here would be a body difference on every
  #       adopted NAT rule.
  #
  # 🔴 2. `destinationAddresses` IS A ONE-ELEMENT LIST BUILT FROM A SCALAR.
  #       RCG L716: `destinationAddresses := []string{condition["destination_address"].(string)}`,
  #       unconditionally. An unset `destination_address` therefore sent
  #       `[""]` -- a list containing the empty string, NOT `[]` and NOT null.
  #       `coalesce` is deliberately NOT used: it skips empty strings and would
  #       produce the wrong value.
  #
  # ⚠️ 3. `translatedAddress` and `translatedFqdn` are the only members on any
  #       rule in this module that AzureRM set CONDITIONALLY (L742, L745, each
  #       under a `!= ""` test). Exactly one of the two must be set -- AzureRM
  #       enforced that in the expander (L719-L724) and `variables.tf` now
  #       carries the same rule as a `validation` block, which fails at plan
  #       time instead of at apply time.
  #
  # `action.type` is passed through verbatim, as AzureRM did. The ARM enum
  # spells the only legal value `DNAT`; AzureRM's own documentation says
  # `Dnat`; ARM accepts what it accepts and this module changes neither.
  # ---------------------------------------------------------------------------
  rule_collections_nat = [
    for collection in coalesce(var.firewall_policy_rule_collection_group_nat_rule_collection, []) : {
      ruleCollectionType = "FirewallPolicyNatRuleCollection"
      name               = collection.name
      priority           = collection.priority
      action = {
        type = collection.action
      }
      rules = [
        for rule in collection.rule : {
          ruleType             = "NatRule"
          name                 = rule.name
          description          = rule.description == null ? "" : rule.description
          ipProtocols          = length(rule.protocols) > 0 ? rule.protocols : null
          sourceAddresses      = coalesce(rule.source_addresses, [])
          sourceIpGroups       = coalesce(rule.source_ip_groups, [])
          destinationAddresses = [rule.destination_address == null ? "" : rule.destination_address]
          destinationPorts     = coalesce(rule.destination_ports, [])
          # ⚠️ NOT `coalesce(x, "") == ""`. Terraform's `coalesce` returns the
          # first argument that is neither null NOR an empty string, so
          # `coalesce(null, "")` has no candidate left and raises
          # "Call to function \"coalesce\" failed: no non-null, non-empty-string
          # arguments" -- which is exactly the case every legal NAT rule hits,
          # because exactly one of these two members is always unset. Found by
          # upgrade-path testing; see `variables.tf`.
          translatedAddress = rule.translated_address == null || rule.translated_address == "" ? null : rule.translated_address
          translatedFqdn    = rule.translated_fqdn == null || rule.translated_fqdn == "" ? null : rule.translated_fqdn
          translatedPort    = tostring(rule.translated_port)
        }
      ]
    }
  ]

  # ---------------------------------------------------------------------------
  # TIMEOUT FALLBACKS. RCG L44-L48: Create 30m, Read 5m, Update 30m,
  # Delete 30m. `var.timeouts` wins, then the legacy
  # `var.firewall_policy_rule_collection_group_timeouts`, then AzureRM's own
  # defaults -- so a consumer who set neither keeps what they had.
  # ---------------------------------------------------------------------------
  timeouts = {
    create = coalesce(var.timeouts.create, var.firewall_policy_rule_collection_group_timeouts == null ? null : var.firewall_policy_rule_collection_group_timeouts.create, "30m")
    delete = coalesce(var.timeouts.delete, var.firewall_policy_rule_collection_group_timeouts == null ? null : var.firewall_policy_rule_collection_group_timeouts.delete, "30m")
    read   = coalesce(var.timeouts.read, var.firewall_policy_rule_collection_group_timeouts == null ? null : var.firewall_policy_rule_collection_group_timeouts.read, "5m")
    update = coalesce(var.timeouts.update, var.firewall_policy_rule_collection_group_timeouts == null ? null : var.firewall_policy_rule_collection_group_timeouts.update, "30m")
  }
}
