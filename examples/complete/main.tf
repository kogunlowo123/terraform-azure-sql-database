provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-sql-complete"
  location = "East US"
}

resource "azurerm_resource_group" "secondary" {
  name     = "rg-sql-complete-secondary"
  location = "West US"
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-sql-complete"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "endpoints" {
  name                 = "snet-endpoints"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "services" {
  name                 = "snet-services"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Sql"]
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "sql-dns-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.example.id
}

resource "azurerm_storage_account" "audit" {
  name                     = "stauditsqlcomplete"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_mssql_server" "secondary" {
  name                         = "sql-complete-secondary"
  resource_group_name          = azurerm_resource_group.secondary.name
  location                     = azurerm_resource_group.secondary.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd1234!"
}

resource "azurerm_user_assigned_identity" "example" {
  name                = "id-sql-complete"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

module "sql_database" {
  source = "../../"

  server_name                   = "sql-complete-example"
  resource_group_name           = azurerm_resource_group.example.name
  location                      = azurerm_resource_group.example.location
  administrator_login           = "sqladmin"
  administrator_login_password  = "P@ssw0rd1234!"
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  connection_policy             = "Redirect"
  identity_type                 = "SystemAssigned, UserAssigned"
  identity_ids                  = [azurerm_user_assigned_identity.example.id]
  primary_user_assigned_identity_id = azurerm_user_assigned_identity.example.id

  azuread_administrator = {
    login_username              = "AzureAD Admin"
    object_id                   = data.azurerm_client_config.current.object_id
    azuread_authentication_only = false
  }

  elastic_pools = {
    "pool-premium" = {
      sku_name                           = "PremiumPool"
      sku_tier                           = "Premium"
      sku_capacity                       = 125
      max_size_gb                        = 50
      zone_redundant                     = true
      per_database_settings_min_capacity = 0
      per_database_settings_max_capacity = 125
    }
  }

  databases = {
    "app-primary" = {
      sku_name           = "P1"
      max_size_gb        = 50
      zone_redundant     = true
      read_scale         = true
      geo_backup_enabled = true
      storage_account_type = "Geo"

      short_term_retention_policy = {
        retention_days           = 35
        backup_interval_in_hours = 12
      }

      long_term_retention_policy = {
        weekly_retention  = "P4W"
        monthly_retention = "P12M"
        yearly_retention  = "P5Y"
        week_of_year      = 1
      }

      threat_detection_policy = {
        state                = "Enabled"
        email_account_admins = "Enabled"
        retention_days       = 90
      }
    }
    "app-pool-db1" = {
      elastic_pool_key = "pool-premium"
      max_size_gb      = 10
    }
    "app-pool-db2" = {
      elastic_pool_key = "pool-premium"
      max_size_gb      = 10
    }
    "app-analytics" = {
      sku_name    = "S2"
      max_size_gb = 250

      short_term_retention_policy = {
        retention_days = 14
      }
    }
  }

  failover_groups = {
    "fg-primary" = {
      partner_server_id = azurerm_mssql_server.secondary.id
      databases         = ["app-primary"]
      read_write_endpoint_failover_policy = {
        mode          = "Automatic"
        grace_minutes = 60
      }
      readonly_endpoint_failover_policy_enabled = true
    }
  }

  firewall_rules = {
    "allow-azure-services" = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  }

  vnet_rules = {
    "allow-services-subnet" = {
      subnet_id = azurerm_subnet.services.id
    }
  }

  auditing_policy = {
    enabled                = true
    storage_endpoint       = azurerm_storage_account.audit.primary_blob_endpoint
    retention_in_days      = 90
    log_monitoring_enabled = true
  }

  security_alert_policy = {
    state                = "Enabled"
    email_account_admins = true
    email_addresses      = ["security@example.com"]
    retention_days       = 90
    storage_endpoint     = azurerm_storage_account.audit.primary_blob_endpoint
  }

  vulnerability_assessment = {
    storage_container_path = "${azurerm_storage_account.audit.primary_blob_endpoint}vulnerability-assessment/"
    recurring_scans = {
      enabled                   = true
      email_subscription_admins = true
      emails                    = ["security@example.com"]
    }
  }

  private_endpoints = {
    "primary" = {
      subnet_id            = azurerm_subnet.endpoints.id
      private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
      subresource_names    = ["sqlServer"]
    }
  }

  tags = {
    Environment = "production"
    Project     = "example"
    CostCenter  = "IT-001"
  }
}

output "server_fqdn" {
  value = module.sql_database.server_fqdn
}

output "failover_group_ids" {
  value = module.sql_database.failover_group_ids
}

output "private_endpoint_ips" {
  value = module.sql_database.private_endpoint_ip_addresses
}
