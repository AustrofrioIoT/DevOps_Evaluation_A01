variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "private_subnets" { type = list(string) }
variable "db_password" { type = string }
variable "lambda_sg_id" { type = string }
