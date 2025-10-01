terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}
provider "azurerm" {
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-05"
    storage_account_name = "stworkshop05"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

resource "azurerm_service_plan" "example" {
  name                = "app-service-plan-rg-05-9542653542"
  location            = "westeurope"
  resource_group_name = "rg-05"
  os_type             = "Linux"
  sku_name            = "P0v3"
}

resource "azurerm_linux_web_app" "example" {
  name                = "webapp-rg-05-9542653542"
  location            = "westeurope"
  resource_group_name = "rg-05"
  service_plan_id     = azurerm_service_plan.example.id
  site_config {}
}