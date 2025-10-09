output "webserver_fqdn" {
  value       = "https://${azurerm_container_app.webserver.latest_revision_fqdn}"
  description = "Endpoint público do Airflow Webserver"
}

output "resource_group" {
  value       = azurerm_resource_group.rg.name
  description = "Nome do Resource Group criado"
}

output "container_app_environment" {
  value       = azurerm_container_app_environment.env.name
  description = "Nome do ambiente ACA"
}
