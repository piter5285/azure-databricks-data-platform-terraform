locals {
  env = var.environment
}

# ─────────────────────────────────────────────
# Assign Workspace to Metastore
# ─────────────────────────────────────────────
resource "databricks_metastore_assignment" "this" {
  metastore_id = var.metastore_id
  workspace_id = var.workspace_id
}

# ─────────────────────────────────────────────
# Groups (idempotent — only created if not exists in account)
# ─────────────────────────────────────────────
resource "databricks_group" "admins" {
  display_name               = var.admin_group_name
  allow_cluster_create       = true
  allow_instance_pool_create = true
}

resource "databricks_group" "data_engineers" {
  display_name         = var.data_engineer_group_name
  allow_cluster_create = true
}

resource "databricks_group" "data_scientists" {
  display_name         = var.data_scientist_group_name
  allow_cluster_create = true
}

resource "databricks_group" "data_analysts" {
  display_name         = var.data_analyst_group_name
  allow_cluster_create = false
}

# ─────────────────────────────────────────────
# Storage Credentials (Access Connector)
# ─────────────────────────────────────────────
resource "databricks_storage_credential" "datalake" {
  name = "sc-datalake-${local.env}"

  azure_managed_identity {
    access_connector_id = var.access_connector_id
  }

  comment = "Managed identity credential for data lake storage - ${local.env}"

  depends_on = [databricks_metastore_assignment.this]
}

resource "databricks_storage_credential" "source_landing" {
  name = "sc-source-landing-${local.env}"

  azure_managed_identity {
    access_connector_id = var.access_connector_id
  }

  comment = "Managed identity credential for source landing storage - ${local.env}"

  depends_on = [databricks_metastore_assignment.this]
}

# ─────────────────────────────────────────────
# External Locations (one per container)
# ─────────────────────────────────────────────
resource "databricks_external_location" "source_landing" {
  name            = "el-source-landing-${local.env}"
  url             = "abfss://source-landing@${var.source_landing_storage_account_name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.source_landing.name
  comment         = "Source landing zone - ${local.env}"
}

resource "databricks_external_location" "bronze" {
  name            = "el-bronze-${local.env}"
  url             = "abfss://bronze@${var.datalake_storage_account_name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.datalake.name
  comment         = "Bronze layer - schema validated Delta tables - ${local.env}"
}

resource "databricks_external_location" "silver" {
  name            = "el-silver-${local.env}"
  url             = "abfss://silver@${var.datalake_storage_account_name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.datalake.name
  comment         = "Silver layer - cleansed/conformed Delta tables - ${local.env}"
}

resource "databricks_external_location" "gold" {
  name            = "el-gold-${local.env}"
  url             = "abfss://gold@${var.datalake_storage_account_name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.datalake.name
  comment         = "Gold layer - analytics and reporting models - ${local.env}"
}

# ─────────────────────────────────────────────
# Catalogs
# ─────────────────────────────────────────────
resource "databricks_catalog" "source" {
  name           = "source_${local.env}"
  comment        = "Source catalog - raw ingested data - ${local.env}"
  storage_root   = databricks_external_location.source_landing.url
  isolation_mode = "ISOLATED"

  depends_on = [databricks_metastore_assignment.this]
}

resource "databricks_catalog" "bronze" {
  name           = "bronze_${local.env}"
  comment        = "Bronze catalog - schema validated Delta tables - ${local.env}"
  storage_root   = databricks_external_location.bronze.url
  isolation_mode = "ISOLATED"

  depends_on = [databricks_metastore_assignment.this]
}

resource "databricks_catalog" "silver" {
  name           = "silver_${local.env}"
  comment        = "Silver catalog - cleansed/conformed Delta tables - ${local.env}"
  storage_root   = databricks_external_location.silver.url
  isolation_mode = "ISOLATED"

  depends_on = [databricks_metastore_assignment.this]
}

resource "databricks_catalog" "gold" {
  name           = "gold_${local.env}"
  comment        = "Gold catalog - analytics and reporting models - ${local.env}"
  storage_root   = databricks_external_location.gold.url
  isolation_mode = "ISOLATED"

  depends_on = [databricks_metastore_assignment.this]
}

# ─────────────────────────────────────────────
# Default Schemas per Catalog
# ─────────────────────────────────────────────
resource "databricks_schema" "source_raw" {
  catalog_name = databricks_catalog.source.name
  name         = "raw"
  comment      = "Raw source files and tables"
}

resource "databricks_schema" "bronze_validated" {
  catalog_name = databricks_catalog.bronze.name
  name         = "validated"
  comment      = "Schema-validated Delta tables"
}

resource "databricks_schema" "silver_cleansed" {
  catalog_name = databricks_catalog.silver.name
  name         = "cleansed"
  comment      = "Cleansed and conformed Delta tables"
}

resource "databricks_schema" "gold_analytics" {
  catalog_name = databricks_catalog.gold.name
  name         = "analytics"
  comment      = "Analytics models and reporting tables"
}

resource "databricks_schema" "gold_reporting" {
  catalog_name = databricks_catalog.gold.name
  name         = "reporting"
  comment      = "Reporting and BI-facing tables"
}

# ─────────────────────────────────────────────
# Catalog Grants
# ─────────────────────────────────────────────
resource "databricks_grants" "source_catalog" {
  catalog = databricks_catalog.source.name

  grant {
    principal  = databricks_group.admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }

  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_CATALOG", "CREATE_SCHEMA", "CREATE_TABLE", "CREATE_VOLUME"]
  }
}

resource "databricks_grants" "bronze_catalog" {
  catalog = databricks_catalog.bronze.name

  grant {
    principal  = databricks_group.admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }

  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_CATALOG", "CREATE_SCHEMA", "CREATE_TABLE", "CREATE_VOLUME", "MODIFY"]
  }
}

resource "databricks_grants" "silver_catalog" {
  catalog = databricks_catalog.silver.name

  grant {
    principal  = databricks_group.admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }

  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_CATALOG", "CREATE_SCHEMA", "CREATE_TABLE", "CREATE_VOLUME", "MODIFY"]
  }

  grant {
    principal  = databricks_group.data_scientists.display_name
    privileges = ["USE_CATALOG", "SELECT"]
  }
}

resource "databricks_grants" "gold_catalog" {
  catalog = databricks_catalog.gold.name

  grant {
    principal  = databricks_group.admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }

  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_CATALOG", "CREATE_SCHEMA", "CREATE_TABLE", "MODIFY"]
  }

  grant {
    principal  = databricks_group.data_scientists.display_name
    privileges = ["USE_CATALOG", "SELECT"]
  }

  grant {
    principal  = databricks_group.data_analysts.display_name
    privileges = ["USE_CATALOG", "SELECT"]
  }
}

# ─────────────────────────────────────────────
# External Location Grants
# ─────────────────────────────────────────────
resource "databricks_grants" "source_landing_location" {
  external_location = databricks_external_location.source_landing.name

  grant {
    principal  = databricks_group.admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }

  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["READ_FILES", "WRITE_FILES", "CREATE_TABLE"]
  }
}

resource "databricks_grants" "bronze_location" {
  external_location = databricks_external_location.bronze.name

  grant {
    principal  = databricks_group.admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }

  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["READ_FILES", "WRITE_FILES", "CREATE_TABLE"]
  }
}

resource "databricks_grants" "silver_location" {
  external_location = databricks_external_location.silver.name

  grant {
    principal  = databricks_group.admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }

  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["READ_FILES", "WRITE_FILES", "CREATE_TABLE"]
  }
}

resource "databricks_grants" "gold_location" {
  external_location = databricks_external_location.gold.name

  grant {
    principal  = databricks_group.admins.display_name
    privileges = ["ALL_PRIVILEGES"]
  }

  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["READ_FILES", "WRITE_FILES", "CREATE_TABLE"]
  }
}
