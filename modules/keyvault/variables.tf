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

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
}

variable "private_endpoints_subnet_id" {
  type        = string
  description = "Subnet ID for private endpoints"
}

variable "private_dns_zone_keyvault_id" {
  type        = string
  description = "Private DNS zone ID for Key Vault"
}

variable "allowed_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs allowed via service endpoints"
  default     = []
}

variable "access_policies" {
  type = list(object({
    object_id               = string
    secret_permissions      = list(string)
    key_permissions         = list(string)
    certificate_permissions = list(string)
  }))
  description = "List of access policies for the Key Vault"
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
