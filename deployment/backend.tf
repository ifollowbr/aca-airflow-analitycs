terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstateairflow"
    container_name       = "tfstate"
    key                  = "aca-airflow.tfstate"
  }
}
