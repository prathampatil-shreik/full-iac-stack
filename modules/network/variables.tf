variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "availability_zones" {
  description = "List of two availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for Terraform-managed private application subnets (must not overlap existing default subnets)"
  type        = list(string)
  default     = ["172.31.100.0/24", "172.31.101.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for Terraform-managed private database subnets (must not overlap existing default subnets)"
  type        = list(string)
  default     = ["172.31.110.0/24", "172.31.111.0/24"]
}
