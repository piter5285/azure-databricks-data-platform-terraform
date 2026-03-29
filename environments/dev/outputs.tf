output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "databricks_workspace_url" {
  value       = module.databricks_workspace.workspace_url
  description = "Databricks workspace URL"
}

output "databricks_workspace_id" {
  value = module.databricks_workspace.workspace_id
}

output "sql_warehouse_jdbc_url" {
  value       = module.databricks_config.sql_warehouse_jdbc_url
  description = "JDBC URL for BI tools / dbt connection"
}

output "sql_warehouse_odbc_params" {
  value = module.databricks_config.sql_warehouse_odbc_params
}

output "source_landing_storage_account" {
  value = module.storage_source.storage_account_name
}

output "datalake_storage_account" {
  value = module.storage_datalake.storage_account_name
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

output "secret_scope_name" {
  value = module.databricks_config.secret_scope_name
}

output "log_analytics_workspace_id" {
  value = module.monitoring.log_analytics_workspace_id
}

output "nat_gateway_public_ip" {
  value       = module.networking.nat_gateway_public_ip
  description = "NAT Gateway egress IP — whitelist in external services"
}

output "governance_cluster_policy_id" {
  value       = module.governance.cost_governance_policy_id
  description = "Cluster policy that enforces cost allocation tags"
}

output "monthly_budget_amount" {
  value       = module.governance.budget_amount
  description = "Configured monthly budget threshold (USD)"
}

# ── Data classification outputs ──────────────
output "governance_catalog_name" {
  value       = module.data_classification.governance_catalog_name
  description = "Catalog containing masking functions: governance_dev.security.*"
}

output "pii_access_group" {
  value       = module.data_classification.pii_access_group_name
  description = "Add users here to grant unmasked PII access"
}

output "masking_functions" {
  value = {
    email         = module.data_classification.fn_mask_email
    phone         = module.data_classification.fn_mask_phone
    name          = module.data_classification.fn_mask_name
    ssn           = module.data_classification.fn_mask_ssn
    credit_card   = module.data_classification.fn_mask_credit_card
    date_of_birth = module.data_classification.fn_mask_date_of_birth
    ip_address    = module.data_classification.fn_mask_ip_address
    hash_pii      = module.data_classification.fn_hash_pii
    nullify       = module.data_classification.fn_nullify_pii
    sensitive             = module.data_classification.fn_mask_sensitive
    policy_confidential   = module.data_classification.fn_policy_confidential
  }
  description = "Fully qualified masking function names. Apply via: ALTER TABLE t ALTER COLUMN c SET MASK <function>(c)"
}
