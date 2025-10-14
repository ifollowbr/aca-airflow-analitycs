variable "prefix" {
  default = "aca-airflow"
}

variable "rg_name" {
  default = "rg-airflow-aca"
}

variable "location" {
  default = "eastus"
}

variable "env_name" {
  default = "env-airflow"
}

variable "airflow_image" {
  default = "apache/airflow:2.9.2"
}

# Banco de dados existente (novo banco "airflow" na mesma instância)
variable "pg_host" {
  default = "sit-datawarehouse.postgres.database.azure.com"
}

variable "pg_database" {
  default = "airflow"
}

variable "pg_port" {
  default = 5432
}

variable "pg_user" {
  default = "ifw_datawarehouse_admin"
}

variable "pg_password" {
  description = "Senha do Postgres existente"
  sensitive   = true
  default     = "ty12$FD@"
}

variable "fernet_key" {
  description = "Chave Fernet do Airflow"
  default     = "yx3uzKzxJm9W4xZQ1Z-TU5htsZV2H3pSk3s3RbTz7xA="
}

variable "webserver_secret_key" {
  description = "Chave secreta do Webserver"
  default     = "c3a1f5b8c9d4a7e0f2b9d1c3e6f7a8b4d9c2e0f3b7a6d5c1"
}
