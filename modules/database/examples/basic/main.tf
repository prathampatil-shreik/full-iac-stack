terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# NOTE: This example requires an existing VPC with private subnets and an
# application security group. In Stage 2, the integrated environment (envs/dev)
# will wire the VPC and Compute module outputs directly into this module.
#
# CREDENTIALS: Never supply db_password in terraform.tfvars or on the command
# line in plain text. Use the environment variable:
#   $env:TF_VAR_db_password = "YourSecurePassword123!"
# Or use AWS Secrets Manager and a data source in production.

module "database" {
  source = "../../"

  project_name              = var.project_name
  environment               = var.environment
  vpc_id                    = var.vpc_id
  private_subnet_ids        = var.private_subnet_ids
  allowed_security_group_id = var.allowed_security_group_id

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  max_allocated_storage   = var.max_allocated_storage
  backup_retention_period = var.backup_retention_period
  multi_az                = var.multi_az
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  tags                    = var.tags
}

output "db_instance_identifier" {
  description = "RDS instance identifier"
  value       = module.database.db_instance_identifier
}

output "db_endpoint" {
  description = "RDS connection endpoint"
  value       = module.database.db_endpoint
}

output "db_port" {
  description = "Database port"
  value       = module.database.db_port
}

output "db_name" {
  description = "Database name"
  value       = module.database.db_name
}
