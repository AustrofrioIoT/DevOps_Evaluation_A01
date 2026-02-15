# Terraform Config
terraform {
  required_version = ">= 1.0.0"

  # Backend S3
  backend "s3" {
    bucket  = "bryam-jelou-terraform-state"
    key     = "devops-test/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider
provider "aws" {
  region = var.aws_region

  # Tags aplicados automáticamente a todos los recursos para facilitar la auditoría y control de costos
  default_tags {
    tags = {
      Project   = "Prueba-Tecnica-Jelou"
      ManagedBy = "Terraform"
      Owner     = "Bryam-Abril"
    }
  }
}

# Modules

# Network
module "network" {
  source       = "./modules/network"
  project_name = var.project_name
}

# Compute
module "compute" {
  source          = "./modules/compute"
  project_name    = var.project_name
  vpc_id          = module.network.vpc_id
  private_subnets = module.network.private_subnets
  db_host         = module.database.db_endpoint
  db_password     = var.db_password
}

# Database
module "database" {
  source          = "./modules/database"
  project_name    = var.project_name
  vpc_id          = module.network.vpc_id
  private_subnets = module.network.private_subnets
  db_password     = var.db_password
  lambda_sg_id    = module.compute.lambda_sg_id
}

# Outputs
output "api_url" {
  value = module.compute.api_url
}

output "db_endpoint" {
  value = module.database.db_endpoint
}
