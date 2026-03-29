variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "log_retention_days" {
  type        = number
  description = "Log Analytics workspace retention in days"
  default     = 30
}

variable "databricks_workspace_id" {
  type        = string
  description = "Databricks workspace resource ID"
}

variable "databricks_workspace_name" {
  type        = string
  description = "Databricks workspace name"
}

variable "key_vault_id" {
  type        = string
  description = "Key Vault resource ID"
  default     = null
}

variable "enable_keyvault_diagnostics" {
  type        = bool
  description = "Whether to create diagnostic settings for Key Vault. Must be a literal true/false, not derived from a resource attribute."
  default     = false
}

variable "storage_account_ids" {
  type        = map(string)
  description = "Map of storage account name => resource ID to enable diagnostics"
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
