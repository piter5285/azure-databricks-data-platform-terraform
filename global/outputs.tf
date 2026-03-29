output "metastore_id" {
  value       = databricks_metastore.this.id
  description = "Unity Catalog Metastore ID — provide this to each environment"
}

output "metastore_storage_account_name" {
  value = azurerm_storage_account.metastore.name
}

output "metastore_access_connector_id" {
  value = azurerm_databricks_access_connector.metastore.id
}

output "global_resource_group_name" {
  value = azurerm_resource_group.global.name
}
