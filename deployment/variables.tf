variable "image" {
  type        = string
  description = "Imagem Docker usada pelo Metabase"
  default     = "metabase/metabase:latest"
}

variable "env_name" {
  type        = string
  description = "Nome do Azure Container Apps Environment"
  default     = "env-metabase"
}

variable "rg_name" {
  type        = string
  description = "Nome do Resource Group (já existente ou a ser criado)"
  default     = "rg-metabase-aca"
}

variable "location" {
  type        = string
  description = "Região Azure (ex.: eastus)"
  default     = "eastus"
}

variable "app_name" {
  type        = string
  description = "Nome do Azure Container App"
  default     = "metabase-app"
}

# Banco de dados do Metabase
variable "db_host" {
  type        = string
  description = "Host do Postgres (Flexible Server)"
}

variable "db_port" {
  type        = string
  description = "Porta do Postgres"
  default     = 5432
}

variable "db_name" {
  type        = string
  description = "Nome do database do Metabase"
  default     = "metabase"
}

variable "db_schema" {
  type        = string
  description = "Schema do Metabase (public recomendado)"
  default     = "public"
}

variable "db_user" {
  type        = string
  description = "Usuário do Postgres (geralmente sem @servername no Flexible Server)"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Senha do Postgres"
}

# Criptografia do Metabase
variable "mb_encryption_secret_key" {
  type        = string
  sensitive   = true
  description = "Chave de criptografia do Metabase (32+ chars)"
}

# Opcional: se vazio, usamos a URL estável do ACA (https://<app>.<region>.azurecontainerapps.io)
variable "site_url_override" {
  type        = string
  description = "URL do site do Metabase. Se vazio, usa domínio fixo do ACA"
  default     = ""
}
