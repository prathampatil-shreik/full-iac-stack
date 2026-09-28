variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from the network module"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "private_app_subnet_ids" {
  description = "Private application subnet IDs for EC2 instances"
  type        = list(string)
}

variable "instance_count" {
  description = "Number of EC2 instances to launch"
  type        = number
  default     = 2
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
  description = "Port the application listens on inside the container"
  type        = number
  default     = 8080
}

variable "nat_gateway_id" {
  description = "NAT Gateway ID — ensures EC2 user_data runs only after outbound internet is available"
  type        = string
}

variable "app_environment" {
  description = "Value for the APP_ENVIRONMENT container environment variable"
  type        = string
  default     = "dev"
}

variable "app_version" {
  description = "Value for the APP_VERSION container environment variable"
  type        = string
  default     = "1.0.0"
}
