variable "environment" {
  type        = string
  description = "Environment name (dev, prep, prod)"
}

variable "project_name" {
  type = string
}

variable "metastore_id" {
  type        = string
  description = "Unity Catalog metastore ID (created in global/)"
}

variable "workspace_id" {
  type        = string
  description = "Databricks workspace numeric ID"
}

variable "access_connector_id" {
  type        = string
  description = "Azure Databricks Access Connector resource ID"
}

variable "datalake_storage_account_name" {
  type        = string
  description = "ADLS Gen2 storage account name for data lake containers"
}

variable "source_landing_storage_account_name" {
  type        = string
  description = "ADLS Gen2 storage account name for source landing"
}

variable "admin_group_name" {
  type        = string
  description = "Name of the Databricks admin group"
  default     = "data-platform-admins"
}

variable "data_engineer_group_name" {
  type        = string
  description = "Name of the data engineers group"
  default     = "data-engineers"
}

variable "data_scientist_group_name" {
  type        = string
  description = "Name of the data scientists group"
  default     = "data-scientists"
}

variable "data_analyst_group_name" {
  type        = string
  description = "Name of the data analysts group"
  default     = "data-analysts"
}
