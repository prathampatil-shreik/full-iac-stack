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
  description = "ID of the VPC where resources will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the Application Load Balancer"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least two public subnet IDs are required for the ALB."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least two private subnet IDs are required for ECS tasks."
  }
}

variable "container_image" {
  description = "Docker image for the ECS task container"
  type        = string
  default     = "nginx:alpine"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80

  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "task_cpu" {
  description = "CPU units for the ECS task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "task_cpu must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Memory (MiB) for the ECS task (must be compatible with task_cpu)"
  type        = number
  default     = 512

  validation {
    condition     = var.task_memory >= 512 && var.task_memory <= 30720
    error_message = "task_memory must be between 512 and 30720 MiB."
  }
}

variable "desired_count" {
  description = "Desired number of ECS task instances"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count must be 0 or greater."
  }
}

variable "health_check_path" {
  description = "HTTP path for ALB target group health checks"
  type        = string
  default     = "/"
}

variable "log_retention_days" {
  description = "CloudWatch log group retention period in days"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch retention value."
  }
}

variable "tags" {
  description = "Map of tags applied to all resources"
  type        = map(string)
  default     = {}
}
