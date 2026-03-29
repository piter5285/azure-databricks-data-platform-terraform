locals {
  prefix = "${var.project_name}-${var.environment}"
}

# ─────────────────────────────────────────────
# Log Analytics Workspace
# ─────────────────────────────────────────────
resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}

# ─────────────────────────────────────────────
# Diagnostic Settings — Databricks Workspace
# ─────────────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "databricks" {
  name                       = "diag-${var.databricks_workspace_name}"
  target_resource_id         = var.databricks_workspace_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "dbfs"
  }

  enabled_log {
    category = "clusters"
  }

  enabled_log {
    category = "accounts"
  }

  enabled_log {
    category = "jobs"
  }

  enabled_log {
    category = "notebook"
  }

  enabled_log {
    category = "ssh"
  }

  enabled_log {
    category = "workspace"
  }

  enabled_log {
    category = "secrets"
  }

  enabled_log {
    category = "sqlPermissions"
  }

  enabled_log {
    category = "instancePools"
  }

  enabled_log {
    category = "sqlanalytics"
  }

  enabled_log {
    category = "genie"
  }

  enabled_log {
    category = "globalInitScripts"
  }

  enabled_log {
    category = "iamRole"
  }

  enabled_log {
    category = "mlflowExperiment"
  }

  enabled_log {
    category = "featureStore"
  }

  enabled_log {
    category = "RemoteHistoryService"
  }

  enabled_log {
    category = "mlflowAcledArtifact"
  }

  enabled_log {
    category = "databrickssql"
  }

  enabled_log {
    category = "deltaPipelines"
  }

  enabled_log {
    category = "modelRegistry"
  }

  enabled_log {
    category = "repos"
  }

  enabled_log {
    category = "unityCatalog"
  }

  enabled_log {
    category = "gitCredentials"
  }

  enabled_log {
    category = "webTerminal"
  }

  enabled_log {
    category = "serverlessRealTimeInference"
  }
}

# ─────────────────────────────────────────────
# Diagnostic Settings — Key Vault (optional)
# ─────────────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  count = var.enable_keyvault_diagnostics ? 1 : 0

  name                       = "diag-kv-${local.prefix}"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
