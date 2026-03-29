variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

# ── SQL Warehouse ────────────────────────────
variable "sql_warehouse_size" {
  type        = string
  description = "SQL Warehouse cluster size: 2X-Small, X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large"
  default     = "Small"
}

variable "sql_warehouse_min_clusters" {
  type    = number
  default = 1
}

variable "sql_warehouse_max_clusters" {
  type    = number
  default = 3
}

variable "sql_warehouse_auto_stop_mins" {
  type        = number
  description = "Minutes of inactivity before auto-stop"
  default     = 15
}

variable "sql_warehouse_spot_instance_policy" {
  type        = string
  description = "COST_OPTIMIZED or RELIABILITY_OPTIMIZED"
  default     = "COST_OPTIMIZED"
}

# ── All-Purpose Cluster ──────────────────────
variable "cluster_autotermination_minutes" {
  type        = number
  description = "Auto-termination for the shared exploration cluster"
  default     = 30
}

variable "cluster_min_workers" {
  type    = number
  default = 1
}

variable "cluster_max_workers" {
  type    = number
  default = 4
}

variable "cluster_node_type" {
  type        = string
  description = "VM SKU for cluster nodes"
  default     = "Standard_DS3_v2"
}

variable "cluster_spark_version" {
  type        = string
  description = "Databricks Runtime version string (use 'latest' for most recent LTS)"
  default     = "15.4.x-scala2.12"
}

# ── Key Vault ────────────────────────────────
variable "key_vault_id" {
  type        = string
  description = "Azure Key Vault resource ID for secret scope backend"
}

variable "key_vault_uri" {
  type        = string
  description = "Azure Key Vault URI"
}

# ── Networking ───────────────────────────────
variable "allowed_ip_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed to access the workspace (IP access list)"
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
