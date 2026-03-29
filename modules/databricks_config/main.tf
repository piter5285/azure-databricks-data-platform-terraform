locals {
  prefix = "${var.project_name}-${var.environment}"
  env    = var.environment
}

# ─────────────────────────────────────────────
# Workspace Configuration
# ─────────────────────────────────────────────
resource "databricks_workspace_conf" "this" {
  custom_config = {
    "enableIpAccessLists"                     = "true"
    "enableTokensConfig"                      = "true"
    "maxTokenLifetimeDays"                    = "90"
    "enableDeprecatedClusterNamedInitScripts" = "false"
    "enableDeprecatedGlobalInitScripts"       = "false"
  }
}

# ─────────────────────────────────────────────
# IP Access List (restrict workspace access)
# ─────────────────────────────────────────────
resource "databricks_ip_access_list" "allowed" {
  count = length(var.allowed_ip_ranges) > 0 ? 1 : 0

  label        = "allowed-ips-${local.env}"
  list_type    = "ALLOW"
  ip_addresses = var.allowed_ip_ranges

  depends_on = [databricks_workspace_conf.this]
}

# ─────────────────────────────────────────────
# Cluster Policies
# ─────────────────────────────────────────────
resource "databricks_cluster_policy" "data_engineering" {
  name = "data-engineering-${local.env}"

  definition = jsonencode({
    "spark_version" = {
      "type"         = "allowlist"
      "values"       = [var.cluster_spark_version, "auto:latest-lts"]
      "defaultValue" = var.cluster_spark_version
    }
    "node_type_id" = {
      "type"         = "allowlist"
      "values"       = ["Standard_DS3_v2", "Standard_DS4_v2", "Standard_DS5_v2"]
      "defaultValue" = var.cluster_node_type
    }
    "autotermination_minutes" = {
      "type"         = "range"
      "minValue"     = 10
      "maxValue"     = 120
      "defaultValue" = var.cluster_autotermination_minutes
    }
    "autoscale.min_workers" = {
      "type"         = "range"
      "minValue"     = 1
      "maxValue"     = 4
      "defaultValue" = var.cluster_min_workers
    }
    "autoscale.max_workers" = {
      "type"         = "range"
      "minValue"     = 1
      "maxValue"     = 10
      "defaultValue" = var.cluster_max_workers
    }
    "spark_conf.spark.databricks.delta.preview.enabled" = {
      "type"  = "fixed"
      "value" = "true"
    }
    "custom_tags.environment" = {
      "type"  = "fixed"
      "value" = local.env
    }
    "custom_tags.project" = {
      "type"  = "fixed"
      "value" = var.project_name
    }
  })
}

resource "databricks_cluster_policy" "data_science" {
  name = "data-science-${local.env}"

  definition = jsonencode({
    "spark_version" = {
      "type"         = "allowlist"
      "values"       = [var.cluster_spark_version, "auto:latest-lts", "auto:latest-lts-ml"]
      "defaultValue" = "auto:latest-lts-ml"
    }
    "node_type_id" = {
      "type"         = "allowlist"
      "values"       = ["Standard_DS3_v2", "Standard_DS4_v2", "Standard_NC6s_v3"]
      "defaultValue" = var.cluster_node_type
    }
    "autotermination_minutes" = {
      "type"         = "range"
      "minValue"     = 10
      "maxValue"     = 240
      "defaultValue" = 60
    }
    "autoscale.min_workers" = {
      "type"         = "range"
      "minValue"     = 1
      "maxValue"     = 8
      "defaultValue" = 1
    }
    "autoscale.max_workers" = {
      "type"         = "range"
      "minValue"     = 1
      "maxValue"     = 16
      "defaultValue" = 4
    }
    "custom_tags.environment" = {
      "type"  = "fixed"
      "value" = local.env
    }
    "custom_tags.project" = {
      "type"  = "fixed"
      "value" = var.project_name
    }
  })
}

# ─────────────────────────────────────────────
# Shared Exploration Cluster (all-purpose)
# ─────────────────────────────────────────────
resource "databricks_cluster" "shared" {
  cluster_name            = "shared-exploration-${local.env}"
  spark_version           = var.cluster_spark_version
  node_type_id            = var.cluster_node_type
  autotermination_minutes = var.cluster_autotermination_minutes
  data_security_mode      = "USER_ISOLATION" # Unity Catalog compatible
  runtime_engine          = "PHOTON"

  autoscale {
    min_workers = var.cluster_min_workers
    max_workers = var.cluster_max_workers
  }

  spark_conf = {
    "spark.databricks.delta.preview.enabled"        = "true"
    "spark.databricks.delta.optimizeWrite.enabled"  = "true"
    "spark.databricks.delta.autoCompact.enabled"    = "true"
    "spark.sql.adaptive.enabled"                    = "true"
    "spark.sql.adaptive.coalescePartitions.enabled" = "true"
  }

  azure_attributes {
    availability       = "SPOT_WITH_FALLBACK_AZURE"
    spot_bid_max_price = -1
    first_on_demand    = 1
  }

  custom_tags = {
    environment  = local.env
    project      = var.project_name
    cluster_type = "shared_exploration"
  }

  cluster_log_conf {
    dbfs {
      destination = "dbfs:/cluster-logs/${local.prefix}"
    }
  }
}

# ─────────────────────────────────────────────
# SQL Warehouse
# ─────────────────────────────────────────────
resource "databricks_sql_endpoint" "this" {
  name                      = "sql-warehouse-${local.env}"
  cluster_size              = var.sql_warehouse_size
  min_num_clusters          = var.sql_warehouse_min_clusters
  max_num_clusters          = var.sql_warehouse_max_clusters
  auto_stop_mins            = var.sql_warehouse_auto_stop_mins
  warehouse_type            = "PRO"
  enable_photon             = true
  enable_serverless_compute = false

  spot_instance_policy = var.sql_warehouse_spot_instance_policy

  channel {
    name = "CHANNEL_NAME_CURRENT"
  }

  tags {
    custom_tags {
      key   = "environment"
      value = local.env
    }
    custom_tags {
      key   = "project"
      value = var.project_name
    }
  }
}

# ─────────────────────────────────────────────
# Secret Scope backed by Azure Key Vault
# ─────────────────────────────────────────────
resource "databricks_secret_scope" "keyvault" {
  name = "keyvault-${local.env}"

  keyvault_metadata {
    resource_id = var.key_vault_id
    dns_name    = var.key_vault_uri
  }
}

# ─────────────────────────────────────────────
# Global Init Script — common libraries / settings
# ─────────────────────────────────────────────
resource "databricks_global_init_script" "common" {
  name     = "common-init-${local.env}"
  enabled  = true
  position = 0

  content_base64 = base64encode(<<-EOT
    #!/bin/bash
    set -euo pipefail

    # Install common Python packages
    pip install --quiet \
      dbt-databricks==1.8.* \
      great-expectations==0.18.* \
      delta-spark==3.2.*

    echo "Common init script completed successfully"
  EOT
  )
}
