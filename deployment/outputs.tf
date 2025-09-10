output "metabase_fqdn" {
  description = "URL pública gerada pelo ACA"
  value       = "https://${azurerm_container_app.metabase.latest_revision_fqdn}"
}

output "resource_group"            { value = azurerm_resource_group.rg.name }
output "container_app_environment" { value = azurerm_container_app_environment.env.name }
