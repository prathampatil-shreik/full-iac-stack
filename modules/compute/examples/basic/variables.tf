variable "project_name" {
  description = "Project name"
  type        = string
  default     = "iac-platform"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID — supply the ID of an existing VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB — must belong to the supplied VPC"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks — must belong to the supplied VPC"
  type        = list(string)
}

variable "container_image" {
  description = "Container image for the ECS task"
  type        = string
  default     = "nginx:alpine"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "task_cpu" {
  description = "ECS task CPU units"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "ECS task memory in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of running ECS tasks"
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "ALB health check path"
  type        = string
  default     = "/"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    Project   = "iac-platform"
    ManagedBy = "Terraform"
  }
}
