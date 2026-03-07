output "server_id" {
  description = "The ID of the SQL Server."
  value       = azurerm_mssql_server.this.id
}

output "server_name" {
  description = "The name of the SQL Server."
  value       = azurerm_mssql_server.this.name
}

output "server_fqdn" {
  description = "The fully qualified domain name of the SQL Server."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "server_identity" {
  description = "The identity block of the SQL Server."
  value       = try(azurerm_mssql_server.this.identity[0], null)
}

output "database_ids" {
  description = "Map of database names to their IDs."
  value       = { for k, v in azurerm_mssql_database.this : k => v.id }
}

output "database_names" {
  description = "Map of database keys to their names."
  value       = { for k, v in azurerm_mssql_database.this : k => v.name }
}

output "elastic_pool_ids" {
  description = "Map of elastic pool names to their IDs."
  value       = { for k, v in azurerm_mssql_elasticpool.this : k => v.id }
}

output "failover_group_ids" {
  description = "Map of failover group names to their IDs."
  value       = { for k, v in azurerm_mssql_failover_group.this : k => v.id }
}

output "failover_group_partner_servers" {
  description = "Map of failover group names to their partner server details."
  value       = { for k, v in azurerm_mssql_failover_group.this : k => v.partner_server }
}

output "firewall_rule_ids" {
  description = "Map of firewall rule names to their IDs."
  value       = { for k, v in azurerm_mssql_firewall_rule.this : k => v.id }
}

output "vnet_rule_ids" {
  description = "Map of VNet rule names to their IDs."
  value       = { for k, v in azurerm_mssql_virtual_network_rule.this : k => v.id }
}

output "private_endpoint_ids" {
  description = "Map of private endpoint names to their IDs."
  value       = { for k, v in azurerm_private_endpoint.this : k => v.id }
}

output "private_endpoint_ip_addresses" {
  description = "Map of private endpoint names to their private IP addresses."
  value       = { for k, v in azurerm_private_endpoint.this : k => v.private_service_connection[0].private_ip_address }
}
