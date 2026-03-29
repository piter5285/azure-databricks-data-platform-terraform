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

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
  default     = ["10.0.0.0/16"]
}

variable "databricks_public_subnet_cidr" {
  type        = string
  description = "CIDR for Databricks public (host) subnet"
}

variable "databricks_private_subnet_cidr" {
  type        = string
  description = "CIDR for Databricks private (container) subnet"
}

variable "private_endpoints_subnet_cidr" {
  type        = string
  description = "CIDR for private endpoints subnet"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
