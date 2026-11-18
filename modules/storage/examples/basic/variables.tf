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

variable "bucket_suffix" {
  description = "Unique suffix for the bucket name — must be globally unique across all AWS accounts"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    Project   = "iac-platform"
    ManagedBy = "Terraform"
  }
}
