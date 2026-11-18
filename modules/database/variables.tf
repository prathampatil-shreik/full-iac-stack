variable "project_name" {
  description = "Project name used in resource naming"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{2,39}$", var.project_name))
    error_message = "project_name must be 3-40 characters, start with a letter or number, and contain only letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment (dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the database will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group (minimum 2)"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least two private subnet IDs are required for the DB subnet group."
  }
}

variable "allowed_security_group_id" {
  description = "Security group ID permitted to connect to the database (e.g. ECS tasks SG)"
  type        = string
}

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "db_name must start with a letter and contain only letters, numbers and underscores."
  }
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_username))
    error_message = "db_username must start with a letter and contain only letters, numbers and underscores."
  }
}

variable "db_password" {
  description = "Master password for the RDS instance — supply via environment variable TF_VAR_db_password or a secrets manager, never hardcode"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "db_password must be at least 8 characters."
  }
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GiB"
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20 GiB for MySQL."
  }
}

variable "max_allocated_storage" {
  description = "Maximum storage autoscaling limit in GiB (0 disables autoscaling)"
  type        = number
  default     = 100
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups (0 disables backups)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35."
  }
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "db_port" {
  description = "Port the database listens on"
  type        = number
  default     = 3306
}

variable "deletion_protection" {
  description = "Enable deletion protection on the RDS instance"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy (set to false in production)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags applied to all resources"
  type        = map(string)
  default     = {}
}
