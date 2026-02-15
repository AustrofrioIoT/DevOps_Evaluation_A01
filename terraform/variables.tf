variable "aws_region" {
  description = "Región de AWS donde se desplegarán todos los recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto."
  type        = string
  default     = "jelou-test"
}

variable "environment" {
  description = "Nombre del entorno (ej: dev, prod, staging)"
  type        = string
  default     = "dev"
}

variable "db_password" {
  description = "Contraseña maestra para la base de datos PostgreSQL"
  type        = string
  sensitive   = true
}
