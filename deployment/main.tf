# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# Log Analytics (necessário para ACA)
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.env_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Ambiente do Azure Container Apps (criado por Terraform)
resource "azurerm_container_app_environment" "env" {
  name                       = var.env_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  lifecycle {
    # impede qualquer tentativa de destruir o Environment
    prevent_destroy = true

    # opcional: evita replace por pequenas mudanças fora do seu controle
    ignore_changes = [
      log_analytics_workspace_id
    ]
  }
}

# Aplicação Metabase no ACA
resource "azurerm_container_app" "metabase" {
  name                = var.app_name
  resource_group_name = azurerm_resource_group.rg.name

  # Usa o Environment criado acima (caminho 1)
  container_app_environment_id = azurerm_container_app_environment.env.id

  revision_mode = "Single"

  # Ingress público (porta 3000 do Metabase)
  ingress {
    external_enabled = true
    target_port      = 3000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  # —— Segredos (todos valores como secrets) ——
  secret {
    name  = "db-host"
    value = var.db_host
  }

  secret {
    name  = "db-port"
    value = tostring(var.db_port)
  }

  secret {
    name  = "db-name"
    value = var.db_name
  }

  secret {
    name  = "db-schema"
    value = var.db_schema
  }

  secret {
    name  = "db-user"
    value = var.db_user
  }

  secret {
    name  = "db-password"
    value = var.db_password
  }

  secret {
    name  = "mb-encryption-key"
    value = var.mb_encryption_secret_key
  }

  secret {
    name  = "db-ssl"
    value = "true"
  }

  secret {
    name  = "db-ssl-mode"
    value = "require"
  }

  secret {
    name  = "db-type"
    value = "postgres"
  }

  # URL estável (não depende de revision/hash)
  secret {
    name  = "site-url"
    value = coalesce(
      var.site_url_override,
      format("https://%s.%s.azurecontainerapps.io", var.app_name, var.location)
    )
  }

  template {
    min_replicas = 1
    max_replicas = 10

    http_scale_rule {
      name                = "http-scaler"
      concurrent_requests = 10
    }

    container {
      name   = "metabase"
      image  = var.image
      cpu    = 2.0
      memory = "4Gi"

      # —— Todos os envs via secret_name ——
      env {
        name        = "MB_DB_TYPE"
        secret_name = "db-type"
      }
      env {
        name        = "MB_DB_HOST"
        secret_name = "db-host"
      }
      env {
        name        = "MB_DB_PORT"
        secret_name = "db-port"
      }
      env {
        name        = "MB_DB_DBNAME"
        secret_name = "db-name"
      }
      env {
        name        = "MB_DB_SCHEMA"
        secret_name = "db-schema"
      }
      env {
        name        = "MB_DB_USER"
        secret_name = "db-user"
      }
      env {
        name        = "MB_DB_PASS"
        secret_name = "db-password"
      }
      env {
        name        = "MB_ENCRYPTION_SECRET_KEY"
        secret_name = "mb-encryption-key"
      }
      env {
        name        = "MB_DB_SSL"
        secret_name = "db-ssl"
      }
      env {
        name        = "MB_DB_SSL_MODE"
        secret_name = "db-ssl-mode"
      }
      env {
        name        = "MB_SITE_URL"
        secret_name = "site-url"
      }

      # —— Probes válidos (sem 'interval') ——
      liveness_probe {
        transport = "HTTP"
        port      = 3000
        path      = "/api/health"
      }

      readiness_probe {
        transport = "HTTP"
        port      = 3000
        path      = "/api/health"
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }
}
