terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.52"
    }
  }

}

provider "azurerm" {
  skip_provider_registration = true

  features {
    key_vault {
      purge_soft_delete_on_destroy    = true # OK in dev
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false # Allow easy teardown in dev
    }
  }
}

provider "azuread" {}

# Workspace-level Databricks provider
# The workspace URL is known only after the workspace is created.
# Terraform handles the dependency graph automatically.
provider "databricks" {
  alias = "workspace"
  host  = module.databricks_workspace.workspace_url

  # Authentication: uses the same Service Principal / Azure CLI as azurerm
  azure_use_msi = false
}
