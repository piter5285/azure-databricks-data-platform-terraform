variable "project_name" {
  type = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "metastore_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.3.0.0/16"]
}

variable "databricks_public_subnet_cidr" {
  type    = string
  default = "10.3.1.0/24"
}

variable "databricks_private_subnet_cidr" {
  type    = string
  default = "10.3.2.0/24"
}

variable "private_endpoints_subnet_cidr" {
  type    = string
  default = "10.3.3.0/24"
}

variable "source_landing_storage_account_name" {
  type = string
}

variable "datalake_storage_account_name" {
  type = string
}

variable "sql_warehouse_size" {
  type    = string
  default = "Small"
}

variable "sql_warehouse_max_clusters" {
  type    = number
  default = 5
}

variable "sql_warehouse_auto_stop_mins" {
  type    = number
  default = 30
}

variable "cluster_node_type" {
  type    = string
  default = "Standard_DS4_v2"
}

variable "cluster_max_workers" {
  type    = number
  default = 8
}

variable "cluster_autotermination_minutes" {
  type    = number
  default = 60
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "Restrict workspace UI access — strongly recommended in prod"
  default     = []
}

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
  type = string
}

variable "monthly_budget_amount" {
  type    = number
  default = 5000
}

variable "budget_alert_emails" {
  type    = list(string)
  default = []
}

variable "allowed_cost_centers" {
  type    = list(string)
  default = ["data-engineering", "data-science", "analytics", "platform", "ml-ops"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
