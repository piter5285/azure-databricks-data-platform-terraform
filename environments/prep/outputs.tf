output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "databricks_workspace_url" {
  value = module.databricks_workspace.workspace_url
}

output "databricks_workspace_id" {
  value = module.databricks_workspace.workspace_id
}

output "sql_warehouse_jdbc_url" {
  value = module.databricks_config.sql_warehouse_jdbc_url
}

output "source_catalog_name" {
  value = module.unity_catalog.source_catalog_name
}

output "bronze_catalog_name" {
  value = module.unity_catalog.bronze_catalog_name
}

output "silver_catalog_name" {
  value = module.unity_catalog.silver_catalog_name
}

output "gold_catalog_name" {
  value = module.unity_catalog.gold_catalog_name
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "nat_gateway_public_ip" {
  value = module.networking.nat_gateway_public_ip
}
