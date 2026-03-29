output "governance_catalog_name" {
  value       = databricks_catalog.governance.name
  description = "Fully qualified governance catalog name"
}

output "security_schema_name" {
  value       = databricks_schema.security.name
  description = "Security schema name within the governance catalog"
}

output "pii_access_group_name" {
  value       = databricks_group.pii_access.display_name
  description = "Group name — members see unmasked PII. Add users via Azure AD / Databricks account console."
}

# ── Fully qualified masking function names ──────────────────
# Use these in: ALTER TABLE t ALTER COLUMN c SET MASK <function>
output "fn_mask_email" {
  value       = "${databricks_catalog.governance.name}.${databricks_schema.security.name}.mask_email"
  description = "Apply to columns tagged class.email_address"
}

output "fn_mask_phone" {
  value       = "${databricks_catalog.governance.name}.${databricks_schema.security.name}.mask_phone"
  description = "Apply to columns tagged class.phone_number"
}

output "fn_mask_name" {
  value       = "${databricks_catalog.governance.name}.${databricks_schema.security.name}.mask_name"
  description = "Apply to columns tagged class.name"
}

output "fn_mask_ssn" {
  value       = "${databricks_catalog.governance.name}.${databricks_schema.security.name}.mask_ssn"
  description = "Apply to columns tagged class.ssn"
}

output "fn_mask_credit_card" {
  value       = "${databricks_catalog.governance.name}.${databricks_schema.security.name}.mask_credit_card"
  description = "Apply to columns tagged class.credit_card (PCI-DSS)"
}

output "fn_mask_date_of_birth" {
  value       = "${databricks_catalog.governance.name}.${databricks_schema.security.name}.mask_date_of_birth"
  description = "Apply to columns tagged class.date_of_birth"
}

output "fn_mask_ip_address" {
  value       = "${databricks_catalog.governance.name}.${databricks_schema.security.name}.mask_ip_address"
  description = "Apply to columns tagged class.ip_address"
}

output "fn_hash_pii" {
  value       = "${databricks_catalog.governance.name}.${databricks_schema.security.name}.hash_pii"
  description = "Deterministic SHA-256 pseudonymisation — preserves join semantics"
}

output "fn_nullify_pii" {
  value       = "${databricks_catalog.governance.name}.${databricks_schema.security.name}.nullify_pii"
  description = "Strictest masking — returns NULL for non-privileged users"
}

output "fn_mask_sensitive" {
  value       = "${databricks_catalog.governance.name}.${databricks_schema.security.name}.mask_sensitive"
  description = "Apply to columns tagged class.sensitive or class.confidential"
}

output "fn_policy_confidential" {
  value       = "${databricks_catalog.governance.name}.${databricks_schema.security.name}.policy_confidential"
  description = "Confidential policy — tag-driven: auto-selects mask for class.name, class.email_address, class.phone_number via has_tag()"
}
