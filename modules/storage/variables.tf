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

variable "bucket_suffix" {
  description = "Unique suffix appended to the bucket name to ensure global uniqueness"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.bucket_suffix))
    error_message = "bucket_suffix must contain only lowercase letters, numbers and hyphens."
  }
}

variable "versioning_enabled" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Map of tags applied to all resources"
  type        = map(string)
  default     = {}
}
