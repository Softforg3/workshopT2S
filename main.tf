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

# Azure Storage Account
resource "azurerm_storage_account" "example" {
  name                     = "stworkshop05storage"
  resource_group_name      = "rg-05"
  location                 = "westeurope"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

# Azure Database for MySQL (burstable)
resource "azurerm_mysql_flexible_server" "burstable" {
  name                   = "mysql-burstable-05-9542653542"
  resource_group_name    = "rg-05"
  location               = "northeurope"
  administrator_login    = "mysqladminuser"
  administrator_password = "P@ssw0rd1234!"
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  zone                   = "1"
  backup_retention_days  = 7
  geo_redundant_backup_enabled = false
  # high_availability i authentication nie są obsługiwane w tym zasobie
}

