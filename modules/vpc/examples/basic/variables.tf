
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "iac-platform"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateways"
  type        = bool
  default     = true
}

variable "nat_gateway_mode" {
  description = "NAT Gateway deployment mode: single or per_az"
  type        = string
  default     = "single"

  validation {
    condition     = contains(["single", "per_az"], var.nat_gateway_mode)
    error_message = "NAT Gateway mode must be either single or per_az."
  }
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default = {
    Project   = "iac-platform"
    ManagedBy = "Terraform"
  }
}
