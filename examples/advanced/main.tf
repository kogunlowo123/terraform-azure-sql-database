provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-sql-advanced"
  location = "East US"
}

data "azurerm_client_config" "current" {}

module "sql_database" {
  source = "../../"

  server_name                   = "sql-advanced-example"
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  administrator_login           = "sqladmin"
  administrator_login_password  = "P@ssw0rd1234!"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = true
  connection_policy             = "Redirect"

  azuread_administrator = {
    login_username              = "AzureAD Admin"
    object_id                   = data.azurerm_client_config.current.object_id
    azuread_authentication_only = false
  }

  elastic_pools = {
    "pool-standard" = {
      sku_name                           = "StandardPool"
      sku_tier                           = "Standard"
      sku_capacity                       = 100
      max_size_gb                        = 50
      per_database_settings_min_capacity = 0
      per_database_settings_max_capacity = 100
    }
  }

  databases = {
    "app-primary" = {
      sku_name    = "S1"
      max_size_gb = 10
      collation   = "SQL_Latin1_General_CP1_CI_AS"

      short_term_retention_policy = {
        retention_days           = 14
        backup_interval_in_hours = 12
      }

      threat_detection_policy = {
        state                = "Enabled"
        email_account_admins = "Enabled"
        retention_days       = 30
      }
    }
    "app-pool-db1" = {
      elastic_pool_key = "pool-standard"
      max_size_gb      = 10
    }
    "app-pool-db2" = {
      elastic_pool_key = "pool-standard"
      max_size_gb      = 10
    }
  }

  firewall_rules = {
    "allow-azure-services" = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
    "office-range" = {
      start_ip_address = "203.0.113.0"
      end_ip_address   = "203.0.113.255"
    }
  }

  auditing_policy = {
    enabled                = true
    retention_in_days      = 90
    log_monitoring_enabled = true
  }

  security_alert_policy = {
    state                = "Enabled"
    email_account_admins = true
    retention_days       = 30
  }

  tags = {
    Environment = "staging"
    Project     = "example"
  }
}

output "server_fqdn" {
  value = module.sql_database.server_fqdn
}

output "elastic_pool_ids" {
  value = module.sql_database.elastic_pool_ids
}
