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

  backend "azurerm" {
    # Fill in backend.tf (copy from backend.tf.example)
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

provider "azuread" {}

# Account-level Databricks provider — used to manage Unity Catalog metastore
provider "databricks" {
  alias      = "account"
  host       = "https://accounts.azuredatabricks.net"
  account_id = var.databricks_account_id

  # Authenticate via Service Principal or Azure CLI
  # Set ARM_CLIENT_ID / ARM_CLIENT_SECRET / ARM_TENANT_ID env vars
  # or use `az login` for interactive sessions
}
