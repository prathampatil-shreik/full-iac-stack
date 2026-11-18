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

module "storage" {
  source = "../../"

  project_name       = var.project_name
  environment        = var.environment
  bucket_suffix      = var.bucket_suffix
  versioning_enabled = var.versioning_enabled
  tags               = var.tags
}

output "bucket_id" {
  description = "S3 bucket ID"
  value       = module.storage.bucket_id
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = module.storage.bucket_name
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.storage.bucket_arn
}

output "bucket_region" {
  description = "S3 bucket region"
  value       = module.storage.bucket_region
}
