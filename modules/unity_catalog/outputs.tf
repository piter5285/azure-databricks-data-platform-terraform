output "source_catalog_name" {
  value = databricks_catalog.source.name
}

output "bronze_catalog_name" {
  value = databricks_catalog.bronze.name
}

output "silver_catalog_name" {
  value = databricks_catalog.silver.name
}

output "gold_catalog_name" {
  value = databricks_catalog.gold.name
}

output "group_admins_id" {
  value = databricks_group.admins.id
}

output "group_data_engineers_id" {
  value = databricks_group.data_engineers.id
}

output "group_data_scientists_id" {
  value = databricks_group.data_scientists.id
}

output "group_data_analysts_id" {
  value = databricks_group.data_analysts.id
}

output "storage_credential_datalake_name" {
  value = databricks_storage_credential.datalake.name
}
