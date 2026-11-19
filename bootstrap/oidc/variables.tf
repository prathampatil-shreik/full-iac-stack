variable "aws_region" {
  description = "AWS region for the OIDC provider and IAM roles"
  type        = string
  default     = "us-east-1"
}

variable "github_org" {
  description = "GitHub organisation or user name that owns the repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without the org prefix)"
  type        = string
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform remote state — needed to grant state access to the CI/CD roles"
  type        = string
  default     = "shreik-iac-platform-tfstate-2026"
}
