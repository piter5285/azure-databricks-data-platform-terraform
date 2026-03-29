variable "project_name" {
  type        = string
  description = "Short project/platform name (lowercase, no spaces)"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "westeurope"
}

variable "metastore_id" {
  type        = string
  description = "Unity Catalog Metastore ID from global/ output"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
}

# ── Networking ───────────────────────────────
variable "vnet_address_space" {
  type    = list(string)
  default = ["10.1.0.0/16"]
}

variable "databricks_public_subnet_cidr" {
  type    = string
  default = "10.1.1.0/24"
}

variable "databricks_private_subnet_cidr" {
  type    = string
  default = "10.1.2.0/24"
}

variable "private_endpoints_subnet_cidr" {
  type    = string
  default = "10.1.3.0/24"
}

# ── Storage ──────────────────────────────────
variable "source_landing_storage_account_name" {
  type        = string
  description = "Globally unique storage account name for source landing"
}

variable "datalake_storage_account_name" {
  type        = string
  description = "Globally unique storage account name for data lake (bronze/silver/gold)"
}

# ── Databricks SQL Warehouse ─────────────────
variable "sql_warehouse_size" {
  type    = string
  default = "2X-Small"
}

variable "sql_warehouse_max_clusters" {
  type    = number
  default = 2
}

variable "sql_warehouse_auto_stop_mins" {
  type    = number
  default = 10
}

# ── Cluster ──────────────────────────────────
variable "cluster_node_type" {
  type    = string
  default = "Standard_DS3_v2"
}

variable "cluster_max_workers" {
  type    = number
  default = 3
}

variable "cluster_autotermination_minutes" {
  type    = number
  default = 20
}

variable "allowed_ip_ranges" {
  type    = list(string)
  default = []
}

# ── Group names (must match unity_catalog module defaults) ───
variable "admin_group_name" {
  type    = string
  default = "data-platform-admins"
}

variable "data_engineer_group_name" {
  type    = string
  default = "data-engineers"
}

# ── Governance ───────────────────────────────
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID (used for policy scoping)"
}

variable "monthly_budget_amount" {
  type        = number
  description = "Monthly budget threshold in USD for this environment"
  default     = 500
}

variable "budget_alert_emails" {
  type        = list(string)
  description = "Email addresses to notify on budget alerts"
  default     = []
}

variable "allowed_cost_centers" {
  type        = list(string)
  description = "Allowed values for the cost_center cluster tag"
  default     = ["data-engineering", "data-science", "analytics", "platform", "ml-ops"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
