locals {
  prefix = "${var.project_name}-${var.environment}"
}

# ─────────────────────────────────────────────
# ADLS Gen2 Storage Account
# ─────────────────────────────────────────────
resource "azurerm_storage_account" "this" {
  name                            = var.storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = var.replication_type
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true # ADLS Gen2
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  public_network_access_enabled   = false
  https_traffic_only_enabled      = true

  blob_properties {
    versioning_enabled  = true
    change_feed_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices", "Logging", "Metrics"]
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = var.tags
}

# ─────────────────────────────────────────────
# Storage Containers
# ─────────────────────────────────────────────
resource "azurerm_storage_container" "this" {
  for_each = toset(var.containers)

  name                  = each.key
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# ─────────────────────────────────────────────
# Private Endpoints
# ─────────────────────────────────────────────
resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob-${var.storage_account_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-blob-${var.storage_account_name}"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnsg-blob-${var.storage_account_name}"
    private_dns_zone_ids = [var.private_dns_zone_blob_id]
  }
}

resource "azurerm_private_endpoint" "dfs" {
  name                = "pe-dfs-${var.storage_account_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-dfs-${var.storage_account_name}"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnsg-dfs-${var.storage_account_name}"
    private_dns_zone_ids = [var.private_dns_zone_dfs_id]
  }
}

# ─────────────────────────────────────────────
# Role Assignments for Databricks Access Connector
# ─────────────────────────────────────────────
resource "azurerm_role_assignment" "access_connector_blob_contributor" {
  count = var.enable_access_connector_role ? 1 : 0

  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.databricks_access_connector_principal_id
}
