output "workspace_id" {
  value = azurerm_databricks_workspace.this.id
}

output "workspace_name" {
  value = azurerm_databricks_workspace.this.name
}

output "workspace_url" {
  value = "https://${azurerm_databricks_workspace.this.workspace_url}"
}

output "workspace_resource_id" {
  value = azurerm_databricks_workspace.this.workspace_id
}

output "managed_resource_group_id" {
  value = azurerm_databricks_workspace.this.managed_resource_group_id
}

output "access_connector_id" {
  value = azurerm_databricks_access_connector.this.id
}

output "access_connector_principal_id" {
  value = azurerm_databricks_access_connector.this.identity[0].principal_id
}
