locals {
  # Build database-to-elastic-pool mapping
  databases_in_pools = {
    for k, v in var.databases : k => v.elastic_pool_key
    if v.elastic_pool_key != null
  }

  # Failover group database IDs (resolved after creation)
  failover_group_databases = {
    for k, v in var.failover_groups : k => [
      for db_name in v.databases : azurerm_mssql_database.this[db_name].id
    ]
  }

  # Default tags
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "terraform-azure-sql-database"
  }

  merged_tags = merge(local.default_tags, var.tags)
}
