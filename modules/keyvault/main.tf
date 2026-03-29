locals {
  prefix = "${var.project_name}-${var.environment}"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                          = "kv-${local.prefix}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = var.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  enable_rbac_authorization     = true
  public_network_access_enabled = false

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  tags = var.tags
}

# ─────────────────────────────────────────────
# Private Endpoint
# ─────────────────────────────────────────────
resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-kv-${local.prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-kv-${local.prefix}"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "pdnsg-kv-${local.prefix}"
    private_dns_zone_ids = [var.private_dns_zone_keyvault_id]
  }
}

# ─────────────────────────────────────────────
# RBAC — Key Vault Secrets Officer for deploying principal
# ─────────────────────────────────────────────
resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
