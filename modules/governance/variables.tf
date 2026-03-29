variable "resource_group_name" {
  type = string
}

variable "resource_group_id" {
  type        = string
  description = "Resource group ID — used for policy assignment and budget scope"
}

variable "location" {
  type = string
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prep, prod)"
}

variable "project_name" {
  type = string
}

variable "subscription_id" {
  type = string
}

# ── Required tags ────────────────────────────
variable "mandatory_tags" {
  type        = list(string)
  description = "Tag keys that must exist on all resources"
  default     = ["environment", "project", "cost_center", "managed_by", "owner"]
}

variable "tag_policy_effect" {
  type        = string
  description = "Azure Policy effect: Deny (strict) or Audit (report-only)"
  default     = "Audit"

  validation {
    condition     = contains(["Audit", "Deny"], var.tag_policy_effect)
    error_message = "tag_policy_effect must be 'Audit' or 'Deny'."
  }
}

# ── Budget alerts ────────────────────────────
variable "monthly_budget_amount" {
  type        = number
  description = "Monthly budget threshold in USD for this environment"
}

variable "budget_alert_thresholds" {
  type        = list(number)
  description = "List of % thresholds to trigger budget alerts (e.g. [80, 100, 120])"
  default     = [80, 100, 120]
}

variable "budget_alert_emails" {
  type        = list(string)
  description = "Email addresses to notify on budget alerts"
  default     = []
}

# ── Databricks tag enforcement ────────────────
variable "required_cluster_tags" {
  type        = map(string)
  description = "Tag key => allowed values map enforced on all clusters (empty list = free text)"
  default = {
    cost_center = ""
    owner       = ""
    team        = ""
  }
}

variable "allowed_cost_centers" {
  type        = list(string)
  description = "Allowed cost_center tag values on Databricks compute"
  default     = ["data-engineering", "data-science", "analytics", "platform"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
