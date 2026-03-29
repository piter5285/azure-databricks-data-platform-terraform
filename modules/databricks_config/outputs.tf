output "shared_cluster_id" {
  value = databricks_cluster.shared.id
}

output "shared_cluster_name" {
  value = databricks_cluster.shared.cluster_name
}

output "sql_warehouse_id" {
  value = databricks_sql_endpoint.this.id
}

output "sql_warehouse_jdbc_url" {
  value = databricks_sql_endpoint.this.jdbc_url
}

output "sql_warehouse_odbc_params" {
  value = databricks_sql_endpoint.this.odbc_params
}

output "secret_scope_name" {
  value = databricks_secret_scope.keyvault.name
}

output "de_cluster_policy_id" {
  value = databricks_cluster_policy.data_engineering.id
}

output "ds_cluster_policy_id" {
  value = databricks_cluster_policy.data_science.id
}
