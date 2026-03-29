output "storage_account_id" {
  value = azurerm_storage_account.this.id
}

output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "storage_account_primary_dfs_endpoint" {
  value = azurerm_storage_account.this.primary_dfs_endpoint
}

output "storage_account_primary_blob_endpoint" {
  value = azurerm_storage_account.this.primary_blob_endpoint
}

output "container_names" {
  value = [for c in azurerm_storage_container.this : c.name]
}

output "private_endpoint_blob_ip" {
  value = azurerm_private_endpoint.blob.private_service_connection[0].private_ip_address
}

output "private_endpoint_dfs_ip" {
  value = azurerm_private_endpoint.dfs.private_service_connection[0].private_ip_address
}
