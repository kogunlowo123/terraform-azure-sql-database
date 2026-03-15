module "test" {
  source = "../"

  server_name         = "sql-server-test-ci"
  resource_group_name = "rg-sql-test"
  location            = "eastus2"
  server_version      = "12.0"

  administrator_login          = "sqladmin"
  administrator_login_password = "T3stP@ssw0rd!2024"

  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
  connection_policy             = "Default"

  databases = {
    appdb = {
      sku_name    = "S0"
      max_size_gb = 2
      collation   = "SQL_Latin1_General_CP1_CI_AS"

      short_term_retention_policy = {
        retention_days           = 7
        backup_interval_in_hours = 12
      }
    }
  }

  firewall_rules = {
    allow-azure-services = {
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }
  }

  tags = {
    environment = "test"
    managed_by  = "terraform"
  }
}
