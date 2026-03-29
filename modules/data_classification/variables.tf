variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "governance_catalog_storage_root" {
  type        = string
  description = "abfss:// URL for the governance catalog storage root"
}

variable "storage_credential_name" {
  type        = string
  description = "Name of the storage credential that has access to the governance catalog storage"
}

# ── Groups ───────────────────────────────────
variable "admin_group_name" {
  type        = string
  description = "Databricks admin group — always gets unmasked access"
}

variable "data_engineer_group_name" {
  type        = string
  description = "Data engineering group — gets unmasked access in non-prod"
}

variable "pii_access_group_name" {
  type        = string
  description = "Group whose members may see real PII values"
  default     = "pii-access"
}

# ── Classification config ─────────────────────
variable "classification_tags" {
  type        = map(string)
  description = "Map of classification tag key => description. These are registered as the governed tag taxonomy."
  default = {
    "class.pii"           = "Personally Identifiable Information — any data that can identify an individual"
    "class.name"          = "Personal name (given name, surname, or full name)"
    "class.email_address" = "Email address"
    "class.phone_number"  = "Phone or mobile number"
    "class.ssn"           = "Social Security Number or national government ID"
    "class.credit_card"   = "Payment card number (PAN)"
    "class.ip_address"    = "IP address that may identify an individual"
    "class.date_of_birth" = "Date of birth"
    "class.sensitive"     = "Sensitive business data (not PII, but restricted)"
    "class.confidential"  = "Confidential — internal only, multiple classification tags may apply"
    "class.public"        = "Public data — no masking required"
  }
}

variable "catalog_names" {
  type        = list(string)
  description = "Catalog names to grant the pii-access group SELECT on (silver, gold)"
  default     = []
}
