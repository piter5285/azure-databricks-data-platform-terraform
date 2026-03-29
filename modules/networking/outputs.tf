output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "databricks_public_subnet_id" {
  value = azurerm_subnet.databricks_public.id
}

output "databricks_public_subnet_name" {
  value = azurerm_subnet.databricks_public.name
}

output "databricks_private_subnet_id" {
  value = azurerm_subnet.databricks_private.id
}

output "databricks_private_subnet_name" {
  value = azurerm_subnet.databricks_private.name
}

output "private_endpoints_subnet_id" {
  value = azurerm_subnet.private_endpoints.id
}

output "nsg_id" {
  value = azurerm_network_security_group.databricks.id
}

output "public_subnet_nsg_association_id" {
  value = azurerm_subnet_network_security_group_association.databricks_public.id
}

output "private_subnet_nsg_association_id" {
  value = azurerm_subnet_network_security_group_association.databricks_private.id
}

output "nat_gateway_public_ip" {
  value = azurerm_public_ip.nat.ip_address
}

output "private_dns_zone_blob_id" {
  value = azurerm_private_dns_zone.blob.id
}

output "private_dns_zone_dfs_id" {
  value = azurerm_private_dns_zone.dfs.id
}

output "private_dns_zone_keyvault_id" {
  value = azurerm_private_dns_zone.keyvault.id
}

output "private_dns_zone_databricks_id" {
  value = azurerm_private_dns_zone.databricks.id
}

output "private_dns_zone_blob_name" {
  value = azurerm_private_dns_zone.blob.name
}

output "private_dns_zone_dfs_name" {
  value = azurerm_private_dns_zone.dfs.name
}

output "private_dns_zone_keyvault_name" {
  value = azurerm_private_dns_zone.keyvault.name
}

output "private_dns_zone_databricks_name" {
  value = azurerm_private_dns_zone.databricks.name
}
