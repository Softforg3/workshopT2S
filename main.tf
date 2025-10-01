terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
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

# Kontener na logi logowań
resource "azurerm_storage_container" "logi_logowan" {
  name                  = "logi_logowan"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

# Key Vault
resource "azurerm_key_vault" "example" {
  name                        = "kvworkshopt2s05"
  location                    = "westeurope"
  resource_group_name         = "rg-05"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  enabled_for_disk_encryption = true
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = ["get", "set", "list"]
  }
}

data "azurerm_client_config" "current" {}

# Secret z hasłem do bazy
resource "azurerm_key_vault_secret" "mysql_password" {
  name         = "mysql-password"
  value        = azurerm_mysql_flexible_server.burstable.administrator_password
  key_vault_id = azurerm_key_vault.example.id
}

# Azure Database for MySQL (burstable)
resource "azurerm_mysql_flexible_server" "burstable" {
  name                   = "mysql-burstable-05-new-9542653542"
  resource_group_name    = "rg-05"
  location               = "polandcentral"
  administrator_login    = "mysqladminuser"
  administrator_password = random_password.mysql_password.result
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  zone                   = "1"
  backup_retention_days  = 7
  geo_redundant_backup_enabled = false
  # high_availability i authentication nie są obsługiwane w tym zasobie
}

# Generowanie losowego hasła do bazy
resource "random_password" "mysql_password" {
  length  = 16
  special = true
}

# Reguła firewalla dla MySQL Flexible Server (dostęp z zewnątrz)
resource "azurerm_mysql_flexible_server_firewall_rule" "allow_my_ip" {
  name                = "allow-all"
  resource_group_name = azurerm_mysql_flexible_server.burstable.resource_group_name
  server_name         = azurerm_mysql_flexible_server.burstable.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

