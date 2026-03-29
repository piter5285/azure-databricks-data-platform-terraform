locals {
  prefix = "${var.project_name}-${var.environment}"
}

# ─────────────────────────────────────────────
# Access Connector (Managed Identity for Unity Catalog)
# ─────────────────────────────────────────────
resource "azurerm_databricks_access_connector" "this" {
  name                = "ac-databricks-${local.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# ─────────────────────────────────────────────
# Databricks Workspace
# ─────────────────────────────────────────────
resource "azurerm_databricks_workspace" "this" {
  name                        = "dbw-${local.prefix}"
  resource_group_name         = var.resource_group_name
  location                    = var.location
  sku                         = var.sku
  managed_resource_group_name = "rg-databricks-managed-${local.prefix}"
  tags                        = var.tags

  custom_parameters {
    no_public_ip                                         = true
    virtual_network_id                                   = var.vnet_id
    public_subnet_name                                   = var.public_subnet_name
    private_subnet_name                                  = var.private_subnet_name
    public_subnet_network_security_group_association_id  = var.public_subnet_nsg_association_id
    private_subnet_network_security_group_association_id = var.private_subnet_nsg_association_id
  }

  # Note: NSG associations must exist before workspace creation.
  # The custom_parameters reference them directly, which creates an
  # implicit dependency in Terraform's plan graph.
}

# ─────────────────────────────────────────────
# Private Endpoint — Databricks UI (browser access)
# ─────────────────────────────────────────────
resource "azurerm_private_endpoint" "databricks_ui" {
  name                = "pe-dbw-ui-${local.prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-dbw-ui-${local.prefix}"
    private_connection_resource_id = azurerm_databricks_workspace.this.id
    subresource_names              = ["browser_authentication"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnsg-dbw-ui-${local.prefix}"
    private_dns_zone_ids = [var.private_dns_zone_databricks_id]
  }
}

resource "azurerm_private_endpoint" "databricks_auth" {
  name                = "pe-dbw-auth-${local.prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-dbw-auth-${local.prefix}"
    private_connection_resource_id = azurerm_databricks_workspace.this.id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnsg-dbw-auth-${local.prefix}"
    private_dns_zone_ids = [var.private_dns_zone_databricks_id]
  }
}
