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

variable "sku" {
  type        = string
  description = "Databricks workspace SKU: standard, premium, trial"
  default     = "premium"
}

variable "vnet_id" {
  type        = string
  description = "VNet ID for VNet injection"
}

variable "public_subnet_name" {
  type        = string
  description = "Name of the public (host) subnet"
}

variable "private_subnet_name" {
  type        = string
  description = "Name of the private (container) subnet"
}

variable "public_subnet_nsg_association_id" {
  type        = string
  description = "NSG association ID for public subnet (used as depends_on equivalent)"
}

variable "private_subnet_nsg_association_id" {
  type        = string
  description = "NSG association ID for private subnet (used as depends_on equivalent)"
}

variable "private_endpoints_subnet_id" {
  type        = string
  description = "Subnet ID for private endpoints"
}

variable "private_dns_zone_databricks_id" {
  type        = string
  description = "Private DNS zone ID for Databricks"
}

variable "tags" {
  type    = map(string)
  default = {}
}
