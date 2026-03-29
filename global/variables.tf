variable "project_name" {
  type        = string
  description = "Short project/platform name used in all resource names (lowercase, no spaces)"
}

variable "location" {
  type        = string
  description = "Primary Azure region"
  default     = "westeurope"
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks account ID (found at accounts.azuredatabricks.net)"
  sensitive   = true
}

variable "metastore_admins_group" {
  type        = string
  description = "Databricks account-level group that will be metastore admin"
  default     = "metastore-admins"
}

variable "metastore_storage_account_name" {
  type        = string
  description = "Globally unique name for the metastore storage account"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all global resources"
  default     = {}
}
