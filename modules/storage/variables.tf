variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prep, prod)"
}

variable "project_name" {
  type        = string
  description = "Project/workload name used in resource naming"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name (must be globally unique, 3-24 lowercase alphanumeric)"
}

variable "replication_type" {
  type        = string
  description = "Storage replication type: LRS, ZRS, GRS, RAGRS, GZRS, RAGZRS"
  default     = "ZRS"
}

variable "containers" {
  type        = list(string)
  description = "List of container names to create"
  default     = []
}

variable "private_endpoints_subnet_id" {
  type        = string
  description = "Subnet ID for private endpoints"
}

variable "private_dns_zone_blob_id" {
  type        = string
  description = "Private DNS zone ID for blob"
}

variable "private_dns_zone_dfs_id" {
  type        = string
  description = "Private DNS zone ID for dfs (ADLS Gen2)"
}

variable "databricks_access_connector_principal_id" {
  type        = string
  description = "Principal ID of the Databricks Access Connector managed identity"
  default     = null
}

variable "enable_access_connector_role" {
  type        = bool
  description = "Whether to assign Storage Blob Data Contributor to the Databricks Access Connector. Must be a literal true/false, not derived from a resource attribute."
  default     = false
}

variable "allowed_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs allowed to access the storage account via service endpoints"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
