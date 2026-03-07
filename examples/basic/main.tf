provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "rg-sql-basic"
  location = "East US"
}

module "sql_database" {
  source = "../../"

  server_name                  = "sql-basic-example"
  resource_group_name          = azurerm_resource_group.example.name
  location                     = azurerm_resource_group.example.location
  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd1234!"

  databases = {
    "app-db" = {
      sku_name    = "S0"
      max_size_gb = 2
    }
  }

  firewall_rules = {
    "allow-azure-services" = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  }

  tags = {
    Environment = "dev"
  }
}

output "server_fqdn" {
  value = module.sql_database.server_fqdn
}

output "database_ids" {
  value = module.sql_database.database_ids
}
