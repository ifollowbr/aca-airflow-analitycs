# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# Log Analytics
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.env_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Environment do ACA
resource "azurerm_container_app_environment" "env" {
  name                       = var.env_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

# Storage Account para DAGs e Logs
resource "azurerm_storage_account" "sa" {
  name                     = lower(replace("${var.prefix}sa", "-", ""))
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "dags" {
  name                 = "dags"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 50
}

resource "azurerm_storage_share" "logs" {
  name                 = "logs"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 100
}

resource "azurerm_container_app_environment_storage" "dags_env" {
  name                         = "dags"
  container_app_environment_id = azurerm_container_app_environment.env.id
  account_name                 = azurerm_storage_account.sa.name
  share_name                   = azurerm_storage_share.dags.name
  access_key                   = azurerm_storage_account.sa.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "logs_env" {
  name                         = "logs"
  container_app_environment_id = azurerm_container_app_environment.env.id
  account_name                 = azurerm_storage_account.sa.name
  share_name                   = azurerm_storage_share.logs.name
  access_key                   = azurerm_storage_account.sa.primary_access_key
  access_mode                  = "ReadWrite"
}

# Redis Cache (para CeleryExecutor)
resource "azurerm_redis_cache" "redis" {
  name                = "${var.prefix}-redis"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  capacity            = 1
  family              = "C"
  sku_name            = "Basic"
  minimum_tls_version = "1.2"
  enable_non_ssl_port = false
}

# Strings de conexão
locals {
  sql_alchemy_conn = "postgresql+psycopg2://${var.pg_user}:${urlencode(var.pg_password)}@${var.pg_host}:${var.pg_port}/${var.pg_database}"
  redis_url        = "rediss://:${azurerm_redis_cache.redis.primary_access_key}@${azurerm_redis_cache.redis.hostname}:6380/0"
}

# Envs comuns do Airflow
locals {
  common_envs = [
    { name = "AIRFLOW__CORE__EXECUTOR", value = "CeleryExecutor" },
    { name = "AIRFLOW__CORE__SQL_ALCHEMY_CONN", value = local.sql_alchemy_conn },
    { name = "AIRFLOW__CELERY__BROKER_URL", value = local.redis_url },
    { name = "AIRFLOW__CELERY__RESULT_BACKEND", value = local.sql_alchemy_conn },
    { name = "AIRFLOW__CORE__FERNET_KEY", value = var.fernet_key },
    { name = "AIRFLOW__WEBSERVER__SECRET_KEY", value = var.webserver_secret_key }
  ]
}

# Webserver
resource "azurerm_container_app" "webserver" {
  name                         = "${var.prefix}-web"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id

  ingress {
    external_enabled = true
    target_port      = 8080
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name   = "airflow-webserver"
      image  = var.airflow_image
      cpu    = 1.0
      memory = "2Gi"
      args   = ["bash", "-lc", "airflow db upgrade && airflow webserver"]

      dynamic "env" {
        for_each = { for e in local.common_envs : e.name => e }
        content {
          name  = env.key
          value = env.value.value
        }
      }

      volume_mounts {
        name = "dags"
        path = "/opt/airflow/dags"
      }

      volume_mounts {
        name = "logs"
        path = "/opt/airflow/logs"
      }
    }

    volume {
      name          = "dags"
      storage_name  = azurerm_container_app_environment_storage.dags_env.name
      storage_type  = "AzureFile"
    }

    volume {
      name          = "logs"
      storage_name  = azurerm_container_app_environment_storage.logs_env.name
      storage_type  = "AzureFile"
    }
  }
}

# Scheduler
resource "azurerm_container_app" "scheduler" {
  name                         = "${var.prefix}-scheduler"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id

  template {
    container {
      name   = "airflow-scheduler"
      image  = var.airflow_image
      cpu    = 1.0
      memory = "2Gi"
      args   = ["bash", "-lc", "airflow db upgrade && airflow scheduler"]

      dynamic "env" {
        for_each = { for e in local.common_envs : e.name => e }
        content {
          name  = env.key
          value = env.value.value
        }
      }

      volume_mounts {
        name = "dags"
        path = "/opt/airflow/dags"
      }

      volume_mounts {
        name = "logs"
        path = "/opt/airflow/logs"
      }
    }

    volume {
      name          = "dags"
      storage_name  = azurerm_container_app_environment_storage.dags_env.name
      storage_type  = "AzureFile"
    }

    volume {
      name          = "logs"
      storage_name  = azurerm_container_app_environment_storage.logs_env.name
      storage_type  = "AzureFile"
    }
  }
}

# Worker
resource "azurerm_container_app" "worker" {
  name                         = "${var.prefix}-worker"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id

  template {
    container {
      name   = "airflow-worker"
      image  = var.airflow_image
      cpu    = 1.0
      memory = "2Gi"
      args   = ["bash", "-lc", "airflow celery worker"]

      dynamic "env" {
        for_each = { for e in local.common_envs : e.name => e }
        content {
          name  = env.key
          value = env.value.value
        }
      }

      volume_mounts {
        name = "dags"
        path = "/opt/airflow/dags"
      }

      volume_mounts {
        name = "logs"
        path = "/opt/airflow/logs"
      }
    }

    volume {
      name          = "dags"
      storage_name  = azurerm_container_app_environment_storage.dags_env.name
      storage_type  = "AzureFile"
    }

    volume {
      name          = "logs"
      storage_name  = azurerm_container_app_environment_storage.logs_env.name
      storage_type  = "AzureFile"
    }
  }
}
