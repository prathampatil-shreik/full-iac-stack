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

# NOTE: This example requires an existing VPC with public and private subnets.
# In Stage 2, the integrated environment (envs/dev) will wire the VPC module
# outputs directly into this module. For standalone validation, supply real
# subnet and VPC IDs via terraform.tfvars or the -var flag.

module "compute" {
  source = "../../"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids

  container_image    = var.container_image
  container_port     = var.container_port
  task_cpu           = var.task_cpu
  task_memory        = var.task_memory
  desired_count      = var.desired_count
  health_check_path  = var.health_check_path
  log_retention_days = var.log_retention_days
  tags               = var.tags
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.compute.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.compute.ecs_service_name
}

output "load_balancer_dns_name" {
  description = "ALB DNS name — access the application at http://<this value>"
  value       = module.compute.load_balancer_dns_name
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = module.compute.ecs_task_execution_role_arn
}
