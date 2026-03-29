output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.this.name
}

output "log_analytics_workspace_key" {
  value     = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive = true
}
