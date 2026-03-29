data "azurerm_client_config" "current" {}

locals {
  tags = merge(var.tags, {
    managed_by = "terraform"
    layer      = "global"
    project    = var.project_name
  })
}

# ─────────────────────────────────────────────
# Resource Group — Global / Metastore
# ─────────────────────────────────────────────
resource "azurerm_resource_group" "global" {
  name     = "rg-${var.project_name}-global"
  location = var.location
  tags     = local.tags
}

# ─────────────────────────────────────────────
# Access Connector for Metastore
# ─────────────────────────────────────────────
resource "azurerm_databricks_access_connector" "metastore" {
  name                = "ac-metastore-${var.project_name}"
  resource_group_name = azurerm_resource_group.global.name
  location            = var.location
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }
}

# ─────────────────────────────────────────────
# Metastore Storage Account (ADLS Gen2)
# ─────────────────────────────────────────────
resource "azurerm_storage_account" "metastore" {
  name                            = var.metastore_storage_account_name
  resource_group_name             = azurerm_resource_group.global.name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  https_traffic_only_enabled      = true

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true
    delete_retention_policy {
      days = 90
    }
    container_delete_retention_policy {
      days = 90
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action = "Allow" # Unity Catalog metastore needs broader access
    bypass         = ["AzureServices", "Logging", "Metrics"]
  }

  tags = local.tags
}

resource "azurerm_storage_container" "metastore" {
  name                  = "metastore"
  storage_account_id    = azurerm_storage_account.metastore.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "ac_metastore_blob_contributor" {
  scope                = azurerm_storage_account.metastore.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.metastore.identity[0].principal_id
}

# ─────────────────────────────────────────────
# Unity Catalog Metastore
# ─────────────────────────────────────────────
resource "databricks_metastore" "this" {
  provider = databricks.account

  name          = "metastore-${var.project_name}-${var.location}"
  region        = var.location
  storage_root  = "abfss://metastore@${azurerm_storage_account.metastore.name}.dfs.core.windows.net/"
  force_destroy = false

  depends_on = [
    azurerm_role_assignment.ac_metastore_blob_contributor,
    azurerm_storage_container.metastore,
  ]
}

resource "databricks_metastore_data_access" "this" {
  provider     = databricks.account
  metastore_id = databricks_metastore.this.id
  name         = "dac-metastore-${var.project_name}"
  is_default   = true

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.metastore.id
  }
}
