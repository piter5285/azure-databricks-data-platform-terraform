locals {
  env             = var.environment
  prefix          = "${var.project_name}-${var.environment}"
  governance_cat  = "governance_${local.env}"
  security_schema = "security"

  # Groups that always see unmasked data — combined for use in SQL CASE expressions
  privileged_groups = [var.admin_group_name, var.pii_access_group_name]
}

# ═════════════════════════════════════════════
# PII Access Group
# ═════════════════════════════════════════════
resource "databricks_group" "pii_access" {
  display_name         = var.pii_access_group_name
  allow_cluster_create = false
}

# ═════════════════════════════════════════════
# Governance Catalog (home for masking functions)
# ═════════════════════════════════════════════
resource "databricks_catalog" "governance" {
  name         = local.governance_cat
  comment      = "Governance catalog: masking functions, classification policies, security schemas — ${local.env}"
  storage_root = var.governance_catalog_storage_root

  properties = {
    "layer"       = "governance"
    "environment" = local.env
    "project"     = var.project_name
  }
}

resource "databricks_schema" "security" {
  catalog_name = databricks_catalog.governance.name
  name         = local.security_schema
  comment      = "Security schema: masking functions and ABAC policies"

  properties = {
    "purpose" = "masking_functions"
  }
}

# ─────────────────────────────────────────────
# Grants on governance catalog
# ─────────────────────────────────────────────
resource "databricks_grants" "governance_catalog" {
  catalog = databricks_catalog.governance.name

  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }

  # All workspace users can USE the catalog (to call masking functions)
  grant {
    principal  = "account users"
    privileges = ["USE_CATALOG", "USE_SCHEMA", "EXECUTE"]
  }
}

resource "databricks_grants" "security_schema" {
  schema = "${databricks_catalog.governance.name}.${databricks_schema.security.name}"

  grant {
    principal  = var.admin_group_name
    privileges = ["ALL_PRIVILEGES"]
  }

  grant {
    principal  = "account users"
    privileges = ["USE_SCHEMA", "EXECUTE"]
  }
}

# ═════════════════════════════════════════════
# Masking Functions — deployed via SQL notebook + job
#
# The Databricks Terraform provider has no resource for
# creating SQL UDFs. Functions are defined in a SQL notebook
# and created/updated by a one-time deploy job.
#
# After first `terraform apply`, trigger the job manually:
#   databricks jobs run-now --job-id <output: masking_functions_job_id>
# or run the notebook directly from the Databricks UI.
#
# The schema-level EXECUTE grant above already covers all
# functions created in the security schema.
# ═════════════════════════════════════════════

resource "databricks_notebook" "masking_functions" {
  path     = "/Shared/${var.project_name}/${var.environment}/governance/masking_functions"
  language = "SQL"

  content_base64 = base64encode(<<-SQL
    USE CATALOG ${local.governance_cat};
    USE SCHEMA ${local.security_schema};

    -- Email: john.smith@company.com → j***@***.com
    CREATE OR REPLACE FUNCTION mask_email(email STRING)
      RETURNS STRING
      LANGUAGE SQL
      DETERMINISTIC
      CONTAINS SQL
      COMMENT 'ABAC mask for class.email_address'
    RETURN
      CASE
        WHEN email IS NULL                              THEN NULL
        WHEN is_member('${var.pii_access_group_name}') THEN email
        WHEN is_member('${var.admin_group_name}')      THEN email
        ELSE regexp_replace(email, '(^.{1})[^@]*(@.{1})[^.]*(\\..*)', '$1***$2***$3')
      END;

    -- Phone: +44 7911 123456 → +** **** ***456
    CREATE OR REPLACE FUNCTION mask_phone(phone STRING)
      RETURNS STRING
      LANGUAGE SQL
      DETERMINISTIC
      CONTAINS SQL
      COMMENT 'ABAC mask for class.phone_number'
    RETURN
      CASE
        WHEN phone IS NULL                              THEN NULL
        WHEN is_member('${var.pii_access_group_name}') THEN phone
        WHEN is_member('${var.admin_group_name}')      THEN phone
        ELSE concat(repeat('*', greatest(length(phone) - 3, 0)), right(phone, 3))
      END;

    -- Name: "John Smith" → "J*** S***"
    CREATE OR REPLACE FUNCTION mask_name(full_name STRING)
      RETURNS STRING
      LANGUAGE SQL
      DETERMINISTIC
      CONTAINS SQL
      COMMENT 'ABAC mask for class.name'
    RETURN
      CASE
        WHEN full_name IS NULL                          THEN NULL
        WHEN is_member('${var.pii_access_group_name}') THEN full_name
        WHEN is_member('${var.admin_group_name}')      THEN full_name
        ELSE regexp_replace(regexp_replace(full_name, '(\\w)(\\w+)', '$1***'), '\\s+', ' ')
      END;

    -- SSN: 123-45-6789 → ***-**-6789
    CREATE OR REPLACE FUNCTION mask_ssn(ssn STRING)
      RETURNS STRING
      LANGUAGE SQL
      DETERMINISTIC
      CONTAINS SQL
      COMMENT 'ABAC mask for class.ssn'
    RETURN
      CASE
        WHEN ssn IS NULL                                THEN NULL
        WHEN is_member('${var.pii_access_group_name}') THEN ssn
        WHEN is_member('${var.admin_group_name}')      THEN ssn
        ELSE regexp_replace(ssn, '[0-9](?=.{4})', '*')
      END;

    -- Credit card: 4111111111111111 → ************1111
    CREATE OR REPLACE FUNCTION mask_credit_card(pan STRING)
      RETURNS STRING
      LANGUAGE SQL
      DETERMINISTIC
      CONTAINS SQL
      COMMENT 'ABAC mask for class.credit_card — PCI-DSS compliant'
    RETURN
      CASE
        WHEN pan IS NULL                                THEN NULL
        WHEN is_member('${var.pii_access_group_name}') THEN pan
        WHEN is_member('${var.admin_group_name}')      THEN pan
        ELSE concat(
               repeat('*', greatest(length(regexp_replace(pan, '[^0-9]', '')) - 4, 0)),
               right(regexp_replace(pan, '[^0-9]', ''), 4))
      END;

    -- Date of birth: 1985-07-23 → 1985-**-**
    CREATE OR REPLACE FUNCTION mask_date_of_birth(dob DATE)
      RETURNS STRING
      LANGUAGE SQL
      DETERMINISTIC
      CONTAINS SQL
      COMMENT 'ABAC mask for class.date_of_birth'
    RETURN
      CASE
        WHEN dob IS NULL                                THEN NULL
        WHEN is_member('${var.pii_access_group_name}') THEN cast(dob AS STRING)
        WHEN is_member('${var.admin_group_name}')      THEN cast(dob AS STRING)
        ELSE concat(year(dob), '-**-**')
      END;

    -- IP address: 192.168.1.42 → 192.168.*.*
    CREATE OR REPLACE FUNCTION mask_ip_address(ip STRING)
      RETURNS STRING
      LANGUAGE SQL
      DETERMINISTIC
      CONTAINS SQL
      COMMENT 'ABAC mask for class.ip_address'
    RETURN
      CASE
        WHEN ip IS NULL                                 THEN NULL
        WHEN is_member('${var.pii_access_group_name}') THEN ip
        WHEN is_member('${var.admin_group_name}')      THEN ip
        ELSE regexp_replace(ip, '(\\d{1,3}\\.\\d{1,3})\\.\\d{1,3}\\.\\d{1,3}', '$1.*.*')
      END;

    -- Hash PII: SHA-256 pseudonymisation, preserves join-ability
    CREATE OR REPLACE FUNCTION hash_pii(value STRING)
      RETURNS STRING
      LANGUAGE SQL
      DETERMINISTIC
      CONTAINS SQL
      COMMENT 'SHA-256 pseudonymisation for non-privileged users'
    RETURN
      CASE
        WHEN value IS NULL                              THEN NULL
        WHEN is_member('${var.pii_access_group_name}') THEN value
        WHEN is_member('${var.admin_group_name}')      THEN value
        ELSE sha2(value, 256)
      END;

    -- Nullify PII: returns NULL for non-privileged users
    CREATE OR REPLACE FUNCTION nullify_pii(value STRING)
      RETURNS STRING
      LANGUAGE SQL
      DETERMINISTIC
      CONTAINS SQL
      COMMENT 'Strictest masking — returns NULL for non-privileged users'
    RETURN
      CASE
        WHEN is_member('${var.pii_access_group_name}') THEN value
        WHEN is_member('${var.admin_group_name}')      THEN value
        ELSE NULL
      END;

    -- Confidential policy: tag-driven, auto-selects mask based on class.* tag
    CREATE OR REPLACE FUNCTION policy_confidential(value STRING)
      RETURNS STRING
      LANGUAGE SQL
      DETERMINISTIC
      CONTAINS SQL
      COMMENT 'Confidential policy — auto-masks based on has_tag()'
    RETURN
      CASE
        WHEN value IS NULL                              THEN NULL
        WHEN is_member('${var.pii_access_group_name}') THEN value
        WHEN is_member('${var.admin_group_name}')      THEN value
        WHEN has_tag('class.name')                      THEN
          regexp_replace(regexp_replace(value, '(\\w)(\\w+)', '$1***'), '\\s+', ' ')
        WHEN has_tag('class.email_address')             THEN
          regexp_replace(value, '(^.{1})[^@]*(@.{1})[^.]*(\\..*)', '$1***$2***$3')
        WHEN has_tag('class.phone_number')              THEN
          concat(repeat('*', greatest(length(value) - 3, 0)), right(value, 3))
        ELSE '[CONFIDENTIAL]'
      END;

    -- Sensitive: generic mask for class.sensitive / class.confidential
    CREATE OR REPLACE FUNCTION mask_sensitive(value STRING)
      RETURNS STRING
      LANGUAGE SQL
      DETERMINISTIC
      CONTAINS SQL
      COMMENT 'Generic mask for class.sensitive / class.confidential'
    RETURN
      CASE
        WHEN value IS NULL                                 THEN NULL
        WHEN is_member('${var.pii_access_group_name}')    THEN value
        WHEN is_member('${var.admin_group_name}')         THEN value
        WHEN is_member('${var.data_engineer_group_name}') THEN
          CASE WHEN '${var.environment}' IN ('dev') THEN value ELSE '[REDACTED]' END
        ELSE '[REDACTED]'
      END;
  SQL
  )

  depends_on = [databricks_schema.security]
}

resource "databricks_job" "masking_functions" {
  name = "${local.prefix}-deploy-masking-functions"

  task {
    task_key = "create_masking_functions"

    notebook_task {
      notebook_path = databricks_notebook.masking_functions.path
      source        = "WORKSPACE"
    }

    new_cluster {
      num_workers   = 1
      spark_version = "15.4.x-scala2.12"
      node_type_id  = "Standard_DS3_v2"

      azure_attributes {
        availability = "ON_DEMAND_AZURE"
      }
    }
  }
}

# ═════════════════════════════════════════════
# PII Access Group — grant on data catalogs
# ═════════════════════════════════════════════
resource "databricks_grants" "pii_access_catalogs" {
  for_each = toset(var.catalog_names)

  catalog = each.key

  grant {
    principal  = databricks_group.pii_access.display_name
    privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  }
}
