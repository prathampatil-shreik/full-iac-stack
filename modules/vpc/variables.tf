
variable "project_name" {
  description = "Project name used in resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{2,39}$", var.project_name))
    error_message = "Project name must be 3-40 characters, start with a letter or number, and contain only letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "Provide a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets"
  type        = list(string)

  validation {
    condition = (
      length(var.public_subnet_cidrs) == 2 &&
      alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))]) &&
      length(distinct(var.public_subnet_cidrs)) == 2
    )
    error_message = "Provide exactly two distinct, valid IPv4 public subnet CIDRs."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the two private subnets"
  type        = list(string)

  validation {
    condition = (
      length(var.private_subnet_cidrs) == 2 &&
      alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))]) &&
      length(distinct(var.private_subnet_cidrs)) == 2
    )
    error_message = "Provide exactly two distinct, valid IPv4 private subnet CIDRs."
  }
}

variable "availability_zones" {
  description = "Two distinct AWS Availability Zones"
  type        = list(string)

  validation {
    condition = (
      length(var.availability_zones) == 2 &&
      length(distinct(var.availability_zones)) == 2 &&
      alltrue([for az in var.availability_zones : length(trimspace(az)) > 0])
    )
    error_message = "Provide exactly two distinct, non-empty Availability Zone names."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateway resources"
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
  default     = {}
}
