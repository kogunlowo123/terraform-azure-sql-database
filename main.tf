resource "azurerm_mssql_server" "this" {
  name                                         = var.server_name
  resource_group_name                          = var.resource_group_name
  location                                     = var.location
  version                                      = var.server_version
  administrator_login                          = var.administrator_login
  administrator_login_password                 = var.administrator_login_password
  minimum_tls_version                          = var.minimum_tls_version
  public_network_access_enabled                = var.public_network_access_enabled
  outbound_network_restriction_enabled         = var.outbound_network_restriction_enabled
  connection_policy                            = var.connection_policy
  primary_user_assigned_identity_id            = var.primary_user_assigned_identity_id
  transparent_data_encryption_key_vault_key_id = var.transparent_data_encryption_key_vault_key_id

  dynamic "azuread_administrator" {
    for_each = var.azuread_administrator != null ? [var.azuread_administrator] : []
    content {
      login_username              = azuread_administrator.value.login_username
      object_id                   = azuread_administrator.value.object_id
      tenant_id                   = azuread_administrator.value.tenant_id
      azuread_authentication_only = azuread_administrator.value.azuread_authentication_only
    }
  }

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }

  tags = var.tags
}

resource "azurerm_mssql_elasticpool" "this" {
  for_each = var.elastic_pools

  name                           = each.key
  resource_group_name            = var.resource_group_name
  location                       = var.location
  server_name                    = azurerm_mssql_server.this.name
  license_type                   = each.value.license_type
  max_size_gb                    = each.value.max_size_gb
  zone_redundant                 = each.value.zone_redundant
  maintenance_configuration_name = each.value.maintenance_configuration_name

  sku {
    name     = each.value.sku_name
    tier     = each.value.sku_tier
    family   = each.value.sku_family
    capacity = each.value.sku_capacity
  }

  per_database_settings {
    min_capacity = each.value.per_database_settings_min_capacity
    max_capacity = each.value.per_database_settings_max_capacity
  }

  tags = var.tags
}

resource "azurerm_mssql_database" "this" {
  for_each = var.databases

  name                                = each.key
  server_id                           = azurerm_mssql_server.this.id
  collation                           = each.value.collation
  license_type                        = each.value.elastic_pool_key == null ? each.value.license_type : null
  sku_name                            = each.value.elastic_pool_key != null ? "ElasticPool" : each.value.sku_name
  max_size_gb                         = each.value.max_size_gb
  zone_redundant                      = each.value.zone_redundant
  read_scale                          = each.value.read_scale
  read_replica_count                  = each.value.read_replica_count
  auto_pause_delay_in_minutes         = each.value.auto_pause_delay_in_minutes
  min_capacity                        = each.value.min_capacity
  elastic_pool_id                     = each.value.elastic_pool_key != null ? azurerm_mssql_elasticpool.this[each.value.elastic_pool_key].id : null
  create_mode                         = each.value.create_mode
  creation_source_database_id         = each.value.creation_source_database_id
  restore_point_in_time               = each.value.restore_point_in_time
  geo_backup_enabled                  = each.value.geo_backup_enabled
  storage_account_type                = each.value.storage_account_type
  ledger_enabled                      = each.value.ledger_enabled
  transparent_data_encryption_enabled = each.value.transparent_data_encryption_enabled

  dynamic "short_term_retention_policy" {
    for_each = each.value.short_term_retention_policy != null ? [each.value.short_term_retention_policy] : []
    content {
      retention_days           = short_term_retention_policy.value.retention_days
      backup_interval_in_hours = short_term_retention_policy.value.backup_interval_in_hours
    }
  }

  dynamic "long_term_retention_policy" {
    for_each = each.value.long_term_retention_policy != null ? [each.value.long_term_retention_policy] : []
    content {
      weekly_retention  = long_term_retention_policy.value.weekly_retention
      monthly_retention = long_term_retention_policy.value.monthly_retention
      yearly_retention  = long_term_retention_policy.value.yearly_retention
      week_of_year      = long_term_retention_policy.value.week_of_year
    }
  }

  dynamic "threat_detection_policy" {
    for_each = each.value.threat_detection_policy != null ? [each.value.threat_detection_policy] : []
    content {
      state                      = threat_detection_policy.value.state
      disabled_alerts            = threat_detection_policy.value.disabled_alerts
      email_account_admins       = threat_detection_policy.value.email_account_admins
      email_addresses            = threat_detection_policy.value.email_addresses
      retention_days             = threat_detection_policy.value.retention_days
      storage_account_access_key = threat_detection_policy.value.storage_account_access_key
      storage_endpoint           = threat_detection_policy.value.storage_endpoint
    }
  }

  tags = var.tags
}

resource "azurerm_mssql_failover_group" "this" {
  for_each = var.failover_groups

  name      = each.key
  server_id = azurerm_mssql_server.this.id
  databases = [for db_name in each.value.databases : azurerm_mssql_database.this[db_name].id]

  partner_server {
    id = each.value.partner_server_id
  }

  read_write_endpoint_failover_policy {
    mode          = each.value.read_write_endpoint_failover_policy.mode
    grace_minutes = each.value.read_write_endpoint_failover_policy.mode == "Automatic" ? each.value.read_write_endpoint_failover_policy.grace_minutes : null
  }

  readonly_endpoint_failover_policy_enabled = each.value.readonly_endpoint_failover_policy_enabled

  tags = var.tags
}

resource "azurerm_mssql_firewall_rule" "this" {
  for_each = var.firewall_rules

  name             = each.key
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

resource "azurerm_mssql_virtual_network_rule" "this" {
  for_each = var.vnet_rules

  name                                 = each.key
  server_id                            = azurerm_mssql_server.this.id
  subnet_id                            = each.value.subnet_id
  ignore_missing_vnet_service_endpoint = each.value.ignore_missing_vnet_service_endpoint
}

resource "azurerm_mssql_server_extended_auditing_policy" "this" {
  count = var.auditing_policy != null ? 1 : 0

  server_id                               = azurerm_mssql_server.this.id
  enabled                                 = var.auditing_policy.enabled
  storage_endpoint                        = var.auditing_policy.storage_endpoint
  storage_account_access_key              = var.auditing_policy.storage_account_access_key
  storage_account_access_key_is_secondary = var.auditing_policy.storage_account_access_key_is_secondary
  retention_in_days                       = var.auditing_policy.retention_in_days
  log_monitoring_enabled                  = var.auditing_policy.log_monitoring_enabled
}

resource "azurerm_mssql_server_security_alert_policy" "this" {
  count = var.security_alert_policy != null ? 1 : 0

  resource_group_name        = var.resource_group_name
  server_name                = azurerm_mssql_server.this.name
  state                      = var.security_alert_policy.state
  disabled_alerts            = var.security_alert_policy.disabled_alerts
  email_account_admins       = var.security_alert_policy.email_account_admins
  email_addresses            = var.security_alert_policy.email_addresses
  retention_days             = var.security_alert_policy.retention_days
  storage_account_access_key = var.security_alert_policy.storage_account_access_key
  storage_endpoint           = var.security_alert_policy.storage_endpoint
}

resource "azurerm_mssql_server_vulnerability_assessment" "this" {
  count = var.vulnerability_assessment != null ? 1 : 0

  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.this[0].id
  storage_container_path          = var.vulnerability_assessment.storage_container_path
  storage_account_access_key      = var.vulnerability_assessment.storage_account_access_key
  storage_container_sas_key       = var.vulnerability_assessment.storage_container_sas_key

  dynamic "recurring_scans" {
    for_each = var.vulnerability_assessment.recurring_scans != null ? [var.vulnerability_assessment.recurring_scans] : []
    content {
      enabled                   = recurring_scans.value.enabled
      email_subscription_admins = recurring_scans.value.email_subscription_admins
      emails                    = recurring_scans.value.emails
    }
  }
}

resource "azurerm_private_endpoint" "this" {
  for_each = var.private_endpoints

  name                = "${var.server_name}-pe-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = each.value.subnet_id

  private_service_connection {
    name                           = "${var.server_name}-psc-${each.key}"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = each.value.subresource_names
    is_manual_connection           = each.value.is_manual_connection
    request_message                = each.value.is_manual_connection ? each.value.request_message : null
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "${var.server_name}-dnsgroup-${each.key}"
      private_dns_zone_ids = each.value.private_dns_zone_ids
    }
  }

  tags = var.tags
}
