terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"        # ajuste
    storage_account_name = "sttfstatemetabase"  # ajuste (nome único no Azure)
    container_name       = "tfstate"
    key                  = "aca-metabase.tfstate"
  }
}
