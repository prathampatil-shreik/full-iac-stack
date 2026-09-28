variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "full-iac-stack"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ---------------------------------------------------------------------------
# Network
# vpc_cidr and public_subnet_cidrs are removed — the existing default VPC
# and its default public subnets are discovered via Terraform data sources.
# ---------------------------------------------------------------------------
variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDRs for Terraform-managed private app subnets inside the default VPC (172.31.0.0/16)"
  type        = list(string)
  default     = ["172.31.100.0/24", "172.31.101.0/24"]
}

variable "private_db_subnet_cidrs" {
  description = "CIDRs for Terraform-managed private DB subnets inside the default VPC (172.31.0.0/16)"
  type        = list(string)
  default     = ["172.31.110.0/24", "172.31.111.0/24"]
}

# ---------------------------------------------------------------------------
# Compute
# ---------------------------------------------------------------------------
variable "instance_count" {
  description = "Number of EC2 application instances"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ecr_image_uri" {
  description = "Full ECR image URI including tag"
  type        = string
}

variable "app_port" {
  description = "Application container port"
  type        = number
  default     = 8080
}

variable "app_environment" {
  description = "APP_ENVIRONMENT value passed to the container"
  type        = string
  default     = "dev"
}

variable "app_version" {
  description = "APP_VERSION value passed to the container"
  type        = string
  default     = "1.0.0"
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------
variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDS master password — supply via TF_VAR_db_password, never commit"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}
