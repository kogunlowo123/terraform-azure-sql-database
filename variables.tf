variable "server_name" {
  description = "The name of the SQL Server."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$", var.server_name))
    error_message = "Server name must be 1-63 characters, contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "location" {
  description = "The Azure region for the SQL Server."
  type        = string
}

variable "server_version" {
  description = "The version of the SQL Server. Valid values are 2.0 (for v11 server) and 12.0 (for v12 server)."
  type        = string
  default     = "12.0"

  validation {
    condition     = contains(["2.0", "12.0"], var.server_version)
    error_message = "Server version must be 2.0 or 12.0."
  }
}

variable "administrator_login" {
  description = "The administrator login name for the SQL Server."
  type        = string
  default     = null
}

variable "administrator_login_password" {
  description = "The administrator login password for the SQL Server."
  type        = string
  default     = null
  sensitive   = true
}

variable "minimum_tls_version" {
  description = "The minimum TLS version for the SQL Server."
  type        = string
  default     = "1.2"

  validation {
    condition     = contains(["1.0", "1.1", "1.2", "Disabled"], var.minimum_tls_version)
    error_message = "Minimum TLS version must be one of: 1.0, 1.1, 1.2, Disabled."
  }
}

variable "public_network_access_enabled" {
  description = "Whether public network access is allowed for this server."
  type        = bool
  default     = false
}

variable "outbound_network_restriction_enabled" {
  description = "Whether outbound network traffic is restricted for this server."
  type        = bool
  default     = false
}

variable "connection_policy" {
  description = "The connection policy for the server. Valid values are Default, Proxy, and Redirect."
  type        = string
  default     = "Default"

  validation {
    condition     = contains(["Default", "Proxy", "Redirect"], var.connection_policy)
    error_message = "Connection policy must be one of: Default, Proxy, Redirect."
  }
}

variable "azuread_administrator" {
  description = "Azure AD administrator configuration for the SQL Server."
  type = object({
    login_username              = string
    object_id                   = string
    tenant_id                   = optional(string, null)
    azuread_authentication_only = optional(bool, false)
  })
  default = null
}

variable "identity_type" {
  description = "The type of managed identity for the SQL Server."
  type        = string
  default     = null

  validation {
    condition     = var.identity_type == null || contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "Identity type must be SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'."
  }
}

variable "identity_ids" {
  description = "A list of user-assigned managed identity IDs."
  type        = list(string)
  default     = []
}

variable "primary_user_assigned_identity_id" {
  description = "The ID of the primary user-assigned identity."
  type        = string
  default     = null
}

variable "transparent_data_encryption_key_vault_key_id" {
  description = "The Key Vault Key URL for transparent data encryption."
  type        = string
  default     = null
}

variable "databases" {
  description = "Map of databases to create on the SQL Server."
  type = map(object({
    collation                   = optional(string, "SQL_Latin1_General_CP1_CI_AS")
    license_type                = optional(string, "LicenseIncluded")
    sku_name                    = optional(string, "S0")
    max_size_gb                 = optional(number, 2)
    zone_redundant              = optional(bool, false)
    read_scale                  = optional(bool, false)
    read_replica_count          = optional(number, 0)
    auto_pause_delay_in_minutes = optional(number, -1)
    min_capacity                = optional(number, null)
    elastic_pool_key            = optional(string, null)
    create_mode                 = optional(string, "Default")
    creation_source_database_id = optional(string, null)
    restore_point_in_time       = optional(string, null)
    geo_backup_enabled          = optional(bool, true)
    storage_account_type        = optional(string, "Geo")
    ledger_enabled              = optional(bool, false)
    transparent_data_encryption_enabled = optional(bool, true)

    short_term_retention_policy = optional(object({
      retention_days           = number
      backup_interval_in_hours = optional(number, 12)
    }), null)

    long_term_retention_policy = optional(object({
      weekly_retention  = optional(string, null)
      monthly_retention = optional(string, null)
      yearly_retention  = optional(string, null)
      week_of_year      = optional(number, null)
    }), null)

    threat_detection_policy = optional(object({
      state                      = optional(string, "Enabled")
      disabled_alerts            = optional(list(string), [])
      email_account_admins       = optional(string, "Enabled")
      email_addresses            = optional(list(string), [])
      retention_days             = optional(number, 30)
      storage_account_access_key = optional(string, null)
      storage_endpoint           = optional(string, null)
    }), null)
  }))
  default = {}
}

variable "elastic_pools" {
  description = "Map of elastic pools to create."
  type = map(object({
    license_type                       = optional(string, "LicenseIncluded")
    max_size_gb                        = optional(number, 50)
    zone_redundant                     = optional(bool, false)
    maintenance_configuration_name     = optional(string, "SQL_Default")
    sku_name                           = optional(string, "StandardPool")
    sku_tier                           = optional(string, "Standard")
    sku_family                         = optional(string, null)
    sku_capacity                       = optional(number, 50)
    per_database_settings_min_capacity = optional(number, 0)
    per_database_settings_max_capacity = optional(number, 50)
  }))
  default = {}
}

variable "failover_groups" {
  description = "Map of failover groups to create."
  type = map(object({
    partner_server_id = string
    databases         = list(string)
    read_write_endpoint_failover_policy = object({
      mode          = string
      grace_minutes = optional(number, 60)
    })
    readonly_endpoint_failover_policy_enabled = optional(bool, true)
  }))
  default = {}
}

variable "firewall_rules" {
  description = "Map of firewall rules to create."
  type = map(object({
    start_ip_address = string
    end_ip_address   = string
  }))
  default = {}
}

variable "vnet_rules" {
  description = "Map of VNet rules to create."
  type = map(object({
    subnet_id                            = string
    ignore_missing_vnet_service_endpoint = optional(bool, false)
  }))
  default = {}
}

variable "auditing_policy" {
  description = "Server-level auditing policy configuration."
  type = object({
    enabled                                 = optional(bool, true)
    storage_endpoint                        = optional(string, null)
    storage_account_access_key              = optional(string, null)
    storage_account_access_key_is_secondary = optional(bool, false)
    retention_in_days                       = optional(number, 90)
    log_analytics_workspace_id              = optional(string, null)
    eventhub_name                           = optional(string, null)
    eventhub_authorization_rule_id          = optional(string, null)
    log_monitoring_enabled                  = optional(bool, true)
  })
  default = null
}

variable "security_alert_policy" {
  description = "Server-level security alert (threat detection) policy."
  type = object({
    state                      = optional(string, "Enabled")
    disabled_alerts            = optional(list(string), [])
    email_account_admins       = optional(bool, true)
    email_addresses            = optional(list(string), [])
    retention_days             = optional(number, 30)
    storage_account_access_key = optional(string, null)
    storage_endpoint           = optional(string, null)
  })
  default = null
}

variable "vulnerability_assessment" {
  description = "Server vulnerability assessment configuration."
  type = object({
    storage_container_path     = string
    storage_account_access_key = optional(string, null)
    storage_container_sas_key  = optional(string, null)
    recurring_scans = optional(object({
      enabled                   = optional(bool, true)
      email_subscription_admins = optional(bool, true)
      emails                    = optional(list(string), [])
    }), null)
  })
  default = null
}

variable "private_endpoints" {
  description = "Map of private endpoints to create."
  type = map(object({
    subnet_id            = string
    private_dns_zone_ids = optional(list(string), [])
    subresource_names    = optional(list(string), ["sqlServer"])
    is_manual_connection = optional(bool, false)
    request_message      = optional(string, null)
  }))
  default = {}
}

variable "tags" {
  description = "A mapping of tags to assign to all resources."
  type        = map(string)
  default     = {}
}
