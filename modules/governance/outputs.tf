output "cost_governance_policy_id" {
  value       = databricks_cluster_policy.cost_governance.id
  description = "Cluster policy ID that enforces cost tags — use as default for new cluster policies"
}

output "cost_governance_policy_name" {
  value = databricks_cluster_policy.cost_governance.name
}

output "mandatory_tag_policy_set_id" {
  value       = azurerm_policy_set_definition.mandatory_tags.id
  description = "Azure Policy initiative ID for mandatory cost tags"
}

output "budget_id" {
  value       = azurerm_consumption_budget_resource_group.this.id
  description = "Azure Cost Management budget ID for this environment"
}

output "budget_amount" {
  value       = azurerm_consumption_budget_resource_group.this.amount
  description = "Monthly budget threshold in USD"
}
