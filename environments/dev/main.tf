locals {
  environment = "dev"
  prefix      = "${var.project_name}-${local.environment}"

  tags = merge(var.tags, {
    environment = local.environment
    project     = var.project_name
    managed_by  = "terraform"
  })
}

# ─────────────────────────────────────────────
# Resource Group
# ─────────────────────────────────────────────
resource "azurerm_resource_group" "this" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.tags
}

# ─────────────────────────────────────────────
# Networking
# ─────────────────────────────────────────────
module "networking" {
  source = "../../modules/networking"

  resource_group_name            = azurerm_resource_group.this.name
  location                       = var.location
  environment                    = local.environment
  project_name                   = var.project_name
  vnet_address_space             = var.vnet_address_space
  databricks_public_subnet_cidr  = var.databricks_public_subnet_cidr
  databricks_private_subnet_cidr = var.databricks_private_subnet_cidr
  private_endpoints_subnet_cidr  = var.private_endpoints_subnet_cidr
  tags                           = local.tags
}

# ─────────────────────────────────────────────
# Source Landing Storage
# ─────────────────────────────────────────────
module "storage_source" {
  source = "../../modules/storage"

  resource_group_name         = azurerm_resource_group.this.name
  location                    = var.location
  environment                 = local.environment
  project_name                = var.project_name
  storage_account_name        = var.source_landing_storage_account_name
  replication_type            = "LRS"
  containers                  = ["source-landing"]
  private_endpoints_subnet_id = module.networking.private_endpoints_subnet_id
  private_dns_zone_blob_id    = module.networking.private_dns_zone_blob_id
  private_dns_zone_dfs_id     = module.networking.private_dns_zone_dfs_id
  allowed_subnet_ids = [
    module.networking.databricks_public_subnet_id,
    module.networking.databricks_private_subnet_id,
  ]
  databricks_access_connector_principal_id = module.databricks_workspace.access_connector_principal_id
  enable_access_connector_role             = true
  tags                                     = local.tags
}

# ─────────────────────────────────────────────
# Data Lake Storage (Bronze / Silver / Gold)
# ─────────────────────────────────────────────
module "storage_datalake" {
  source = "../../modules/storage"

  resource_group_name         = azurerm_resource_group.this.name
  location                    = var.location
  environment                 = local.environment
  project_name                = var.project_name
  storage_account_name        = var.datalake_storage_account_name
  replication_type            = "LRS"
  containers                  = ["bronze", "silver", "gold", "governance"]
  private_endpoints_subnet_id = module.networking.private_endpoints_subnet_id
  private_dns_zone_blob_id    = module.networking.private_dns_zone_blob_id
  private_dns_zone_dfs_id     = module.networking.private_dns_zone_dfs_id
  allowed_subnet_ids = [
    module.networking.databricks_public_subnet_id,
    module.networking.databricks_private_subnet_id,
  ]
  databricks_access_connector_principal_id = module.databricks_workspace.access_connector_principal_id
  enable_access_connector_role             = true
  tags                                     = local.tags
}

# ─────────────────────────────────────────────
# Key Vault
# ─────────────────────────────────────────────
module "keyvault" {
  source = "../../modules/keyvault"

  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  environment                  = local.environment
  project_name                 = var.project_name
  tenant_id                    = var.tenant_id
  private_endpoints_subnet_id  = module.networking.private_endpoints_subnet_id
  private_dns_zone_keyvault_id = module.networking.private_dns_zone_keyvault_id
  allowed_subnet_ids = [
    module.networking.databricks_public_subnet_id,
    module.networking.databricks_private_subnet_id,
  ]
  tags = local.tags
}

# ─────────────────────────────────────────────
# Databricks Workspace
# ─────────────────────────────────────────────
module "databricks_workspace" {
  source = "../../modules/databricks_workspace"

  resource_group_name               = azurerm_resource_group.this.name
  location                          = var.location
  environment                       = local.environment
  project_name                      = var.project_name
  sku                               = "premium"
  vnet_id                           = module.networking.vnet_id
  public_subnet_name                = module.networking.databricks_public_subnet_name
  private_subnet_name               = module.networking.databricks_private_subnet_name
  public_subnet_nsg_association_id  = module.networking.public_subnet_nsg_association_id
  private_subnet_nsg_association_id = module.networking.private_subnet_nsg_association_id
  private_endpoints_subnet_id       = module.networking.private_endpoints_subnet_id
  private_dns_zone_databricks_id    = module.networking.private_dns_zone_databricks_id
  tags                              = local.tags
}

# ─────────────────────────────────────────────
# Monitoring
# ─────────────────────────────────────────────
module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name       = azurerm_resource_group.this.name
  location                  = var.location
  environment               = local.environment
  project_name              = var.project_name
  log_retention_days        = 30
  databricks_workspace_id   = module.databricks_workspace.workspace_id
  databricks_workspace_name = module.databricks_workspace.workspace_name
  key_vault_id                = module.keyvault.key_vault_id
  enable_keyvault_diagnostics = true
  tags                        = local.tags
}

# ─────────────────────────────────────────────
# Unity Catalog (workspace-level)
# ─────────────────────────────────────────────
module "unity_catalog" {
  source = "../../modules/unity_catalog"

  providers = {
    databricks = databricks.workspace
  }

  environment                         = local.environment
  project_name                        = var.project_name
  metastore_id                        = var.metastore_id
  workspace_id                        = module.databricks_workspace.workspace_resource_id
  access_connector_id                 = module.databricks_workspace.access_connector_id
  datalake_storage_account_name       = module.storage_datalake.storage_account_name
  source_landing_storage_account_name = module.storage_source.storage_account_name

  depends_on = [
    module.databricks_workspace,
    module.storage_datalake,
    module.storage_source,
  ]
}

# ─────────────────────────────────────────────
# Databricks Configuration (workspace-level)
# ─────────────────────────────────────────────
module "databricks_config" {
  source = "../../modules/databricks_config"

  providers = {
    databricks = databricks.workspace
  }

  environment                        = local.environment
  project_name                       = var.project_name
  sql_warehouse_size                 = var.sql_warehouse_size
  sql_warehouse_min_clusters         = 1
  sql_warehouse_max_clusters         = var.sql_warehouse_max_clusters
  sql_warehouse_auto_stop_mins       = var.sql_warehouse_auto_stop_mins
  sql_warehouse_spot_instance_policy = "COST_OPTIMIZED"
  cluster_autotermination_minutes    = var.cluster_autotermination_minutes
  cluster_min_workers                = 1
  cluster_max_workers                = var.cluster_max_workers
  cluster_node_type                  = var.cluster_node_type
  cluster_spark_version              = "15.4.x-scala2.12"
  key_vault_id                       = module.keyvault.key_vault_id
  key_vault_uri                      = module.keyvault.key_vault_uri
  allowed_ip_ranges                  = var.allowed_ip_ranges
  tags                               = local.tags

  depends_on = [
    module.unity_catalog,
    module.keyvault,
  ]
}

# ─────────────────────────────────────────────
# Governance — Tag policies, budgets, compute tag enforcement
# ─────────────────────────────────────────────
module "governance" {
  source = "../../modules/governance"

  providers = {
    databricks = databricks.workspace
  }

  resource_group_name     = azurerm_resource_group.this.name
  resource_group_id       = azurerm_resource_group.this.id
  location                = var.location
  environment             = local.environment
  project_name            = var.project_name
  subscription_id         = var.subscription_id
  monthly_budget_amount   = var.monthly_budget_amount
  budget_alert_emails     = var.budget_alert_emails
  budget_alert_thresholds = [80, 100, 120]
  tag_policy_effect       = "Audit" # non-blocking in dev
  allowed_cost_centers    = var.allowed_cost_centers
  tags                    = local.tags

  depends_on = [module.databricks_config]
}

# ─────────────────────────────────────────────
# Data Classification — masking functions + ABAC
# ─────────────────────────────────────────────
module "data_classification" {
  source = "../../modules/data_classification"

  providers = {
    databricks = databricks.workspace
  }

  environment  = local.environment
  project_name = var.project_name

  governance_catalog_storage_root = "abfss://governance@${module.storage_datalake.storage_account_name}.dfs.core.windows.net/"
  storage_credential_name         = module.unity_catalog.storage_credential_datalake_name

  admin_group_name         = var.admin_group_name
  data_engineer_group_name = var.data_engineer_group_name

  # Catalogs where the pii-access group gets SELECT
  catalog_names = [
    module.unity_catalog.silver_catalog_name,
    module.unity_catalog.gold_catalog_name,
  ]

  depends_on = [
    module.unity_catalog,
    module.storage_datalake,
  ]
}
