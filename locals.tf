# =============================================================================
# REQUEST BODIES for the AzAPI migration of `azurerm_firewall_policy`.
#
# THE RULE THIS FILE FOLLOWS, in one sentence: every member below is here
# because `hashicorp/azurerm` v4.81.0 put it on the wire, and it is shaped and
# conditioned exactly the way that provider shaped and conditioned it.
#
# The source of truth is `internal/services/network/firewall_policy_resource.go`
# at v4.81.0 (cited below as "FWP L<n>"). Its `Create` and `Update` are the SAME
# function, `resourceFirewallPolicyCreateUpdate` (FWP L60): it builds `props`
# from scratch on every apply, issues NO GET, carries NOTHING forward from the
# live object, and calls `CreateOrUpdateThenPoll`. That single fact is why this
# module uses a PLAIN FULL WRITER and not the create-only + merge-writer split
# used for `azurerm_firewall` in the vWAN pattern repository -- see the header
# of `main.tf`.
#
# The member names are read from the ARM type set, not from memory:
# bicep-types-az `network/microsoft.network/2025-07-01`, cached locally at
# `~/.cache/azure-schema/network_microsoft.network_2025-07-01_types.json`.
#
# 🔴 NULL MEANS ABSENT, NOT `null`. `azapi_resource.this` sets
# `ignore_null_property = true`, so every `null` below is PRUNED from the
# outgoing request rather than sent as an explicit JSON null. That is precisely
# AzureRM's `*T` + `json:",omitempty"` serialisation: an optional the consumer
# left unset never reached ARM. Members AzureRM sent as EMPTY-BUT-PRESENT
# (`[]`, `""`) are not null, so they survive the prune and are still sent --
# see `intrusionDetection.configuration` below, which is the main such case.
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # `parent_id` for the policy. AzureRM composed the identical string inside
  # `firewallpolicies.NewFirewallPolicyID(subscriptionId, resourceGroupName,
  # name)` (FWP L67) and stored the result as the resource `id`.
  #
  # 🔴 THIS STRING MUST MATCH THE `parentId` THAT `azapi` PARSES OUT OF THE
  # MIGRATED `id`, CHARACTER FOR CHARACTER, BECAUSE `parent_id` IS A
  # REPLACEMENT TRIGGER. `azapi_resource.MoveState`
  # (`internal/services/azapi_resource.go` L1478, v2.13.0) reads the AzureRM
  # `id` out of the source state and sets `ParentID` from
  # `parse.ResourceID(azureId)`. The `resource_group_name` branch is built from
  # the SAME variable AzureRM used, and `resourceGroups` is spelled the way
  # AzureRM spelled it, so the two agree. Do not "tidy" the casing.
  #
  # ⚠️ AN UPGRADING CONSUMER SHOULD KEEP PASSING `resource_group_name`. Both
  # branches produce the same string when the subscription matches, but
  # `var.parent_id` is supplied by the consumer and a difference of a single
  # character -- `resourcegroups`, a trailing slash, a different subscription --
  # replaces the policy instead of adopting it. Switch to `parent_id` in a
  # separate change, after the migration plan has come back empty.
  # ---------------------------------------------------------------------------
  firewall_policy_parent_id = var.parent_id != null ? var.parent_id : "/subscriptions/${data.azapi_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"

  firewall_policy_subscription_id = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", local.firewall_policy_parent_id).subscription_id

  # ---------------------------------------------------------------------------
  # THE POLICY BODY.
  #
  # ⚠️ `location`, `tags`, `name` and `identity` are DELIBERATELY ABSENT from
  # this object. They are first-class `azapi_resource` arguments, and
  # `flattenBody` -- the function that populates `state.body` for a resource
  # that has just been adopted by a `moved` block -- deletes exactly those four
  # keys before writing the state (`internal/services/resource.go` L167-L187,
  # v2.13.0) and then keeps only the WRITABLE members via
  # `resourceDef.GetWriteOnly`. Putting any of the four in `body` would
  # guarantee a permanent diff against the migrated state.
  # ---------------------------------------------------------------------------
  firewall_policy_body = {
    properties = {
      # FWP L131: `props.Properties.BasePolicy` is set only under
      # `d.GetOk("base_policy_id")`, so an unset base policy was omitted.
      basePolicy = var.firewall_policy_base_policy_id == null ? null : {
        id = var.firewall_policy_base_policy_id
      }

      # FWP L113: `DnsSettings: expandFirewallPolicyDNSSetting(d.Get("dns"))`,
      # and that expander returns nil for an absent block -- so the whole member
      # is omitted unless the consumer supplied `firewall_policy_dns`.
      #
      # Inside the block AzureRM sent BOTH members unconditionally:
      #   - `Servers: utils.ExpandStringSlice(raw["servers"])`, which returns a
      #     pointer to an EMPTY slice (never nil) for an unset list, so `[]`
      #     went on the wire;
      #   - `EnableProxy: raw["proxy_enabled"]`, a `TypeBool` whose schema
      #     `Default` is `false` (FWP L708), so `false` went on the wire.
      # Both are reproduced, `[]` and `false` included, so an adopted policy
      # sees no change.
      #
      # ⚠️ `properties.dnsSettings.requireProxyForNetworkRules` exists in the
      # ARM type and is NOT declared here. AzureRM had no schema field for it
      # either, so this is parity, not a new gap. A consumer who needs it uses
      # `ignore_body_changes` and an out-of-band controller.
      dnsSettings = var.firewall_policy_dns == null ? null : {
        servers     = var.firewall_policy_dns.servers == null ? [] : var.firewall_policy_dns.servers
        enableProxy = var.firewall_policy_dns.proxy_enabled == null ? false : var.firewall_policy_dns.proxy_enabled
      }

      # FWP L116 + `expandFirewallPolicyExplicitProxy`. Absent block -> nil ->
      # member omitted. Present block -> AzureRM sent all six members, reading
      # each through `raw[...]` with the schema zero value standing in for an
      # unset optional (`0` for the ports, `""` for the PAC file URL, `false`
      # for the two booleans). `EnablePacFile` is guarded by
      # `if val, ok := raw["enable_pac_file"]; ok`, but the key of a declared
      # `TypeBool` is ALWAYS present in the expanded map, so that guard never
      # excluded it.
      explicitProxy = var.firewall_policy_explicit_proxy == null ? null : {
        enableExplicitProxy = var.firewall_policy_explicit_proxy.enabled == null ? false : var.firewall_policy_explicit_proxy.enabled
        enablePacFile       = var.firewall_policy_explicit_proxy.enable_pac_file == null ? false : var.firewall_policy_explicit_proxy.enable_pac_file
        httpPort            = var.firewall_policy_explicit_proxy.http_port == null ? 0 : var.firewall_policy_explicit_proxy.http_port
        httpsPort           = var.firewall_policy_explicit_proxy.https_port == null ? 0 : var.firewall_policy_explicit_proxy.https_port
        pacFile             = var.firewall_policy_explicit_proxy.pac_file == null ? "" : var.firewall_policy_explicit_proxy.pac_file
        pacFilePort         = var.firewall_policy_explicit_proxy.pac_file_port == null ? 0 : var.firewall_policy_explicit_proxy.pac_file_port
      }

      # FWP L115 + `expandFirewallPolicyInsights` +
      # `expandFirewallPolicyLogAnalyticsResources`.
      #
      # 🔴 `workspaces` IS ALWAYS PRESENT, EVEN WHEN EMPTY. The expander builds
      # the slice with `make([]T, 0, len(workspaces))` and then guards the
      # assignment with `if workspaceList != nil` -- a slice from `make` is
      # never nil, so the guard is always true and `"workspaces": []` went on
      # the wire whenever the `insights` block existed. Reproduced.
      #
      # `retentionDays` is `int64(raw["retention_in_days"].(int))`, i.e. `0`
      # when the consumer left it unset, not omitted.
      insights = var.firewall_policy_insights == null ? null : {
        isEnabled     = var.firewall_policy_insights.enabled
        retentionDays = var.firewall_policy_insights.retention_in_days == null ? 0 : var.firewall_policy_insights.retention_in_days
        logAnalyticsResources = {
          defaultWorkspaceId = {
            id = var.firewall_policy_insights.default_log_analytics_workspace_id
          }
          workspaces = [
            for workspace in coalesce(var.firewall_policy_insights.log_analytics_workspace, []) : {
              region = workspace.firewall_location
              workspaceId = {
                id = workspace.id
              }
            }
          ]
        }
      }

      # FWP L114 + `expandFirewallPolicyIntrusionDetection`.
      #
      # 🔴 THE `configuration` OBJECT IS THE ONE PLACE WHERE EMPTY-BUT-PRESENT
      # MATTERS. AzureRM built all three of `signatureOverrides`,
      # `privateRanges` and `bypassTrafficSettings` with `make(..., 0, len(...))`
      # and took their addresses unconditionally, so `configuration` always
      # carried three arrays -- empty ones when the consumer configured nothing.
      # Those arrays are NOT null, so `ignore_null_property` leaves them alone
      # and they are still sent. Turning any of them into `null` here would
      # change the request AzureRM made and would show up as a diff on adoption.
      #
      # `mode` is likewise unconditional: `FirewallPolicyIntrusionDetectionStateType(raw["mode"].(string))`
      # yields the EMPTY STRING when the consumer left `mode` unset, and an
      # empty string is not a null.
      #
      # Note the ARM member for a signature override's state is `mode`, not
      # `state` -- AzureRM's schema attribute is `state`
      # (`FirewallPolicyIntrusionDetectionSignatureSpecification.Mode`).
      #
      # ⚠️ `properties.intrusionDetection.profile` exists in the ARM type and is
      # NOT declared. AzureRM had no schema field for it either -- parity.
      intrusionDetection = var.firewall_policy_intrusion_detection == null ? null : {
        mode = var.firewall_policy_intrusion_detection.mode == null ? "" : var.firewall_policy_intrusion_detection.mode
        configuration = {
          privateRanges = coalesce(var.firewall_policy_intrusion_detection.private_ranges, [])
          signatureOverrides = [
            for override in coalesce(var.firewall_policy_intrusion_detection.signature_overrides, []) : {
              id   = override.id == null ? "" : override.id
              mode = override.state == null ? "" : override.state
            }
          ]
          bypassTrafficSettings = [
            for bypass in coalesce(var.firewall_policy_intrusion_detection.traffic_bypass, []) : {
              name                 = bypass.name
              protocol             = bypass.protocol
              description          = bypass.description == null ? "" : bypass.description
              sourceAddresses      = tolist(coalesce(bypass.source_addresses, []))
              sourceIpGroups       = tolist(coalesce(bypass.source_ip_groups, []))
              destinationAddresses = tolist(coalesce(bypass.destination_addresses, []))
              destinationIpGroups  = tolist(coalesce(bypass.destination_ip_groups, []))
              destinationPorts     = tolist(coalesce(bypass.destination_ports, []))
            }
          ]
        }
      }

      # FWP L143: `d.GetOk("sku")`. The schema carries `Default: "Standard"`
      # (FWP L677), and `GetOk` on a non-empty string is always true, so
      # AzureRM sent `sku.tier` on EVERY apply -- `"Standard"` when the
      # consumer left `firewall_policy_sku` unset. `coalesce` reproduces that.
      #
      # 🔴 THIS PATH IS THE `replace_triggers_refs` ENTRY IN `main.tf`. FWP L677
      # marks `sku` ForceNew, so AzureRM destroyed and recreated the policy when
      # it changed; the trigger keeps that behaviour rather than silently
      # attempting an in-place tier change that ARM rejects.
      sku = {
        tier = coalesce(var.firewall_policy_sku, "Standard")
      }

      # FWP L155 + L163. Two SEPARATE `d.GetOk` guards feeding ONE `snat`
      # object, and the combination is fiddly enough to be worth spelling out:
      #
      #   - `private_ip_ranges` is a `TypeList`; `GetOk` is false for an empty
      #     or absent list, so `snat` was created only for a NON-EMPTY list.
      #   - `auto_learn_private_ranges_enabled` is a `TypeBool`; `GetOk` is
      #     false for `false` as well as for unset. AzureRM then created `snat`
      #     if it did not already exist and set
      #     `AutoLearnPrivateRanges = "Enabled"` -- there is no code path that
      #     ever sent `"Disabled"`.
      #
      # So: `snat` is omitted entirely unless at least one of the two applies,
      # and each member inside it is omitted unless its own guard applies.
      # Setting `firewall_policy_auto_learn_private_ranges_enabled = false` on
      # a policy that already has it enabled is therefore a NO-OP -- it was a
      # no-op under AzureRM too, for the same reason.
      snat = (
        length(coalesce(var.firewall_policy_private_ip_ranges, [])) > 0 ||
        var.firewall_policy_auto_learn_private_ranges_enabled == true
        ) ? {
        privateRanges          = length(coalesce(var.firewall_policy_private_ip_ranges, [])) > 0 ? var.firewall_policy_private_ip_ranges : null
        autoLearnPrivateRanges = var.firewall_policy_auto_learn_private_ranges_enabled == true ? "Enabled" : null
      } : null

      # FWP L149: `d.GetOk("sql_redirect_allowed")`, a `TypeBool`, so the guard
      # is false for BOTH unset and `false` and the `sql` member was omitted in
      # both cases. Same no-op-on-false caveat as `autoLearnPrivateRanges`.
      sql = var.firewall_policy_sql_redirect_allowed == true ? {
        allowSqlRedirect = true
      } : null

      # FWP L111: `ThreatIntelMode` is assigned from a bare `d.Get`, with no
      # `ok` guard, so it was on EVERY request. The schema `Default` is
      # `"Alert"` (FWP L719), which is the value AzureRM sent when the consumer
      # left `firewall_policy_threat_intelligence_mode` unset -- hence the
      # `coalesce`, without which an adopted policy would diff from `"Alert"`
      # to absent.
      threatIntelMode = coalesce(var.firewall_policy_threat_intelligence_mode, "Alert")

      # FWP L112 + `expandFirewallPolicyThreatIntelWhitelist`. Absent block ->
      # nil -> omitted. Present block -> both members sent, `[]` when the
      # corresponding set is empty (`ExpandStringSlice` again never returns
      # nil). The variable's sets are converted with `tolist` because ARM's
      # type is an array and a Terraform `set` would order differently.
      threatIntelWhitelist = var.firewall_policy_threat_intelligence_allowlist == null ? null : {
        fqdns       = tolist(coalesce(var.firewall_policy_threat_intelligence_allowlist.fqdns, []))
        ipAddresses = tolist(coalesce(var.firewall_policy_threat_intelligence_allowlist.ip_addresses, []))
      }

      # FWP L117 + `expandFirewallPolicyTransportSecurity`. Absent block -> nil
      # -> omitted. Both members of `certificateAuthority` are required by this
      # module's variable, so neither needs a fallback.
      transportSecurity = var.firewall_policy_tls_certificate == null ? null : {
        certificateAuthority = {
          keyVaultSecretId = var.firewall_policy_tls_certificate.key_vault_secret_id
          name             = var.firewall_policy_tls_certificate.name
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # PER-RESOURCE TIMEOUT FALLBACKS.
  #
  # An attribute the consumer leaves unset does NOT fall back to one blanket
  # value; it falls back to the timeout of the `hashicorp/azurerm` v4.81.0
  # resource that this module's AzAPI resource replaced, so a migrated
  # deployment keeps the timeouts it already had.
  #
  #   - firewall policy: create 30m, read 5m, update 30m, delete 30m
  #     (`firewall_policy_resource.go` L52-57).
  #   - diagnostic settings: create 30m, read 5m, update 30m, delete **60m**
  #     (`monitor_diagnostic_setting_resource.go` L43-48). Note the 60m delete,
  #     which is NOT the policy's 30m.
  #   - lock and role assignments: 30m across the board, matching
  #     `azurerm_management_lock` and `azurerm_role_assignment`.
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # 🔴 THE `retry` OBJECT IS COLLAPSED TO `null` WHEN NO REGEX IS CONFIGURED.
  #
  # `azapi_resource.retry` is an OPTIONAL single-nested attribute whose
  # `error_message_regex` member the PROVIDER marks REQUIRED. Handing the
  # provider a PRESENT object with a null regex list therefore fails the plan
  # outright:
  #
  #     Error: Missing Configuration for Required Attribute
  #     Must set a configuration value for the retry.error_message_regex
  #     attribute as the provider has marked it as required.
  #
  # A bare `retry = var.retry` is safe only while the DEFAULT regex list is
  # non-null. It is not a property of the default -- it is a property of the
  # value the consumer supplies. `retry = { interval_seconds = 30 }` or
  # `retry = { error_message_regex = null }` is a legal value of this
  # variable's type and made all four writers unplannable. Found on the
  # submodule during upgrade-path testing and fixed there; this
  # is the same guard at the parent, which had the identical latent defect on
  # `azapi_resource.this`, `.lock`, `.role_assignments` and
  # `.diagnostic_settings`.
  #
  # `terraform validate` does not catch it. Only a real plan does.
  # ---------------------------------------------------------------------------
  azapi_retry = var.retry.error_message_regex == null ? null : var.retry

  # ---------------------------------------------------------------------------
  timeouts = {
    authorization_locks = {
      create = coalesce(var.timeouts.create, "30m")
      delete = coalesce(var.timeouts.delete, "30m")
      read   = coalesce(var.timeouts.read, "5m")
      update = coalesce(var.timeouts.update, "30m")
    }
    authorization_role_assignments = {
      create = coalesce(var.timeouts.create, "30m")
      delete = coalesce(var.timeouts.delete, "30m")
      read   = coalesce(var.timeouts.read, "5m")
      update = coalesce(var.timeouts.update, "30m")
    }
    insights_diagnostic_settings = {
      create = coalesce(var.timeouts.create, "30m")
      delete = coalesce(var.timeouts.delete, "60m")
      read   = coalesce(var.timeouts.read, "5m")
      update = coalesce(var.timeouts.update, "30m")
    }
    network_firewall_policies = {
      create = coalesce(var.timeouts.create, var.firewall_policy_timeouts == null ? null : var.firewall_policy_timeouts.create, "30m")
      delete = coalesce(var.timeouts.delete, var.firewall_policy_timeouts == null ? null : var.firewall_policy_timeouts.delete, "30m")
      read   = coalesce(var.timeouts.read, var.firewall_policy_timeouts == null ? null : var.firewall_policy_timeouts.read, "5m")
      update = coalesce(var.timeouts.update, var.firewall_policy_timeouts == null ? null : var.firewall_policy_timeouts.update, "30m")
    }
  }

  # ---------------------------------------------------------------------------
  # NULL-SAFETY FOR THE THREE READ-ONLY BACK-REFERENCES.
  #
  # `data.azapi_resource.this` projects each `SubResource[]` down to its `id`
  # with JMESPath. A JMESPath projection over a member ARM did not return
  # evaluates to NULL, not to `[]` -- a brand new policy has no firewalls, no
  # child policies and no rule collection groups -- so every consumer of these
  # outputs would otherwise have to null-check. AzureRM's
  # `flattenNetworkSubResourceID` returned an empty list in the same situation,
  # so `[]` is also the parity answer.
  #
  # `try(tolist(...), [])` covers both the null case and the case where the
  # export key is absent entirely.
  # ---------------------------------------------------------------------------
  firewall_policy_child_policies         = try(tolist(data.azapi_resource.this.output.child_policies), [])
  firewall_policy_firewalls              = try(tolist(data.azapi_resource.this.output.firewalls), [])
  firewall_policy_rule_collection_groups = try(tolist(data.azapi_resource.this.output.rule_collection_groups), [])
}
