locals {
  prefix = "${var.project_name}-${var.environment}"
  env    = var.environment
}

# ═════════════════════════════════════════════
# AZURE POLICY — Mandatory tag enforcement
# ═════════════════════════════════════════════

# One policy definition per required tag key
resource "azurerm_policy_definition" "require_tag" {
  for_each = toset(var.mandatory_tags)

  name         = "require-tag-${each.key}-${local.prefix}"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "[${upper(local.env)}] Require tag: ${each.key}"
  description  = "Enforces that all tagged resources in ${local.env} carry the '${each.key}' tag."

  policy_rule = jsonencode({
    if = {
      field  = "tags['${each.key}']"
      exists = "false"
    }
    then = {
      effect = var.tag_policy_effect
    }
  })

  metadata = jsonencode({
    category = "Tags"
    version  = "1.0.0"
  })
}

# Initiative (policy set) — bundles all mandatory tag policies
resource "azurerm_policy_set_definition" "mandatory_tags" {
  name         = "mandatory-tags-${local.prefix}"
  policy_type  = "Custom"
  display_name = "[${upper(local.env)}] Mandatory cost allocation tags"
  description  = "Requires ${join(", ", var.mandatory_tags)} on all indexed resources."

  dynamic "policy_definition_reference" {
    for_each = azurerm_policy_definition.require_tag
    content {
      policy_definition_id = policy_definition_reference.value.id
      reference_id         = "require-tag-${policy_definition_reference.key}"
    }
  }

  metadata = jsonencode({ category = "Tags" })

  depends_on = [azurerm_policy_definition.require_tag]
}

# Assign to the environment resource group
resource "azurerm_resource_group_policy_assignment" "mandatory_tags" {
  name                 = "tags-${local.env}"
  resource_group_id    = var.resource_group_id
  policy_definition_id = azurerm_policy_set_definition.mandatory_tags.id
  display_name         = "[${upper(local.env)}] Mandatory cost allocation tags"
}

# ─────────────────────────────────────────────
# Tag inheritance — propagate RG tags to resources
# Uses the built-in Azure Policy (no custom def needed)
# ─────────────────────────────────────────────
locals {
  # Built-in policy IDs for "Inherit a tag from the resource group"
  inherit_tag_policy_ids = {
    environment = "/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"
    project     = "/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"
    cost_center = "/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"
  }
}

resource "azurerm_resource_group_policy_assignment" "inherit_tag" {
  for_each = toset(["environment", "project", "cost_center"])

  name                 = "inherit-tag-${each.key}-${local.env}"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"
  display_name         = "[${upper(local.env)}] Inherit tag '${each.key}' from RG"

  # This built-in policy requires a 'tagName' parameter
  parameters = jsonencode({
    tagName = { value = each.key }
  })

  identity {
    type = "SystemAssigned"
  }

  location = var.location
}

# Grant Tag Contributor so the Modify effect can write tags
resource "azurerm_role_assignment" "policy_tag_contributor" {
  for_each = azurerm_resource_group_policy_assignment.inherit_tag

  scope                = var.resource_group_id
  role_definition_name = "Tag Contributor"
  principal_id         = each.value.identity[0].principal_id
}

# ═════════════════════════════════════════════
# AZURE COST MANAGEMENT — Budget alerts per env
# ═════════════════════════════════════════════
resource "azurerm_consumption_budget_resource_group" "this" {
  name              = "budget-${local.prefix}"
  resource_group_id = var.resource_group_id
  amount            = var.monthly_budget_amount
  time_grain        = "Monthly"

  time_period {
    # Start on the 1st of the current month (budget is ongoing)
    start_date = formatdate("YYYY-MM-01'T'00:00:00'Z'", timestamp())
  }

  # Actual spend alerts (e.g. 80 %, 100 %)
  dynamic "notification" {
    for_each = [for t in var.budget_alert_thresholds : t if t <= 100]
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThan"
      threshold_type = "Actual"
      contact_emails = var.budget_alert_emails
    }
  }

  # Forecasted overspend alert (e.g. 120 %)
  dynamic "notification" {
    for_each = [for t in var.budget_alert_thresholds : t if t > 100]
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThan"
      threshold_type = "Forecasted"
      contact_emails = var.budget_alert_emails
    }
  }
}

# ═════════════════════════════════════════════
# DATABRICKS — Compute tag governance
# Cluster policy that enforces cost allocation tags
# on ALL clusters and jobs in this workspace
# ═════════════════════════════════════════════
resource "databricks_cluster_policy" "cost_governance" {
  name = "cost-governance-${local.env}"

  definition = jsonencode({
    # ── Fixed tags injected automatically ──────────────────────────
    "custom_tags.environment" = {
      type  = "fixed"
      value = local.env
    }
    "custom_tags.project" = {
      type  = "fixed"
      value = var.project_name
    }
    "custom_tags.managed_by" = {
      type  = "fixed"
      value = "terraform"
    }

    # ── Required — user must choose from allowed list ──────────────
    "custom_tags.cost_center" = {
      type         = "allowlist"
      values       = var.allowed_cost_centers
      defaultValue = var.allowed_cost_centers[0]
    }
    "custom_tags.team" = {
      type   = "allowlist"
      values = ["data-engineering", "data-science", "analytics", "platform", "ml-ops"]
    }

    # ── Required — free-text, minimum 3 chars (forces real owner) ──
    "custom_tags.owner" = {
      type    = "regex"
      pattern = ".{3,}"
    }

    # ── Cost control — always enforce autotermination ──────────────
    "autotermination_minutes" = {
      type         = "range"
      minValue     = 10
      maxValue     = 240
      defaultValue = 30
    }

    # ── Spot by default in non-prod (overridable) ──────────────────
    "azure_attributes.availability" = {
      type         = "allowlist"
      values       = ["SPOT_WITH_FALLBACK_AZURE", "ON_DEMAND_AZURE"]
      defaultValue = local.env == "prod" ? "ON_DEMAND_AZURE" : "SPOT_WITH_FALLBACK_AZURE"
    }
  })
}

# ─────────────────────────────────────────────
# Make cost-governance policy the default for
# users who cannot choose a policy themselves
# ─────────────────────────────────────────────
resource "databricks_permissions" "cost_governance_policy" {
  cluster_policy_id = databricks_cluster_policy.cost_governance.id

  access_control {
    group_name       = "users" # all workspace users
    permission_level = "CAN_USE"
  }
}

# ═════════════════════════════════════════════
# DATABRICKS — Workspace configuration
# Token lifetimes + IP access enforcement
# ═════════════════════════════════════════════
resource "databricks_workspace_conf" "governance" {
  custom_config = {
    # Token governance
    "enableTokensConfig"   = "true"
    "maxTokenLifetimeDays" = local.env == "prod" ? "30" : "90"

    # Enforce IP access lists (actual list is in databricks_config module)
    "enableIpAccessLists" = "true"

    # Prevent legacy passthrough auth (Unity Catalog requirement)
    "enableDeprecatedClusterNamedInitScripts" = "false"
    "enableDeprecatedGlobalInitScripts"       = "false"
  }
}
