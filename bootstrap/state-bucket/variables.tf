variable "aws_region" {
  description = "AWS region where the state bucket will be created"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = <<-EOT
    Globally unique name for the Terraform remote state S3 bucket.
    AWS S3 general-purpose bucket naming rules:
      - 3 to 63 characters
      - Lowercase letters, numbers, hyphens and periods only
      - Must start and end with a letter or number
      - No consecutive periods (..)
      - No adjacent period-hyphen (.- or -.) combinations
      - Must not be formatted as an IP address (e.g. 192.168.1.1)
      - Must not start with the reserved prefix xn--
      - Must not end with the reserved suffixes -s3alias or --ol-s3
  EOT
  type        = string

  validation {
    condition = (
      # Rule 1: 3-63 characters, allowed character set: lowercase, digits, hyphens, periods
      can(regex("^[a-z0-9][a-z0-9.\\-]{1,61}[a-z0-9]$", var.state_bucket_name)) &&

      # Rule 2: No consecutive periods
      !can(regex("\\.\\.", var.state_bucket_name)) &&

      # Rule 3: No period-hyphen or hyphen-period adjacency
      !can(regex("(\\.\\-|\\-\\.)", var.state_bucket_name)) &&

      # Rule 4: Must not look like an IPv4 address (four dot-separated octets)
      !can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", var.state_bucket_name)) &&

      # Rule 5: Must not start with the IDN reserved prefix xn--
      !can(regex("^xn--", var.state_bucket_name)) &&

      # Rule 6: Must not end with reserved S3 suffixes
      !can(regex("(-s3alias|--ol-s3)$", var.state_bucket_name))
    )
    error_message = <<-EOT
      state_bucket_name does not meet AWS S3 bucket naming requirements.
      Use 3-63 lowercase letters, numbers, hyphens or periods.
      Must start and end with a letter or number.
      No consecutive periods, no period-hyphen adjacency, no IP-address format.
      Must not start with 'xn--' or end with '-s3alias' or '--ol-s3'.
    EOT
  }
}

variable "project_name" {
  description = "Project name applied as a resource tag"
  type        = string
  default     = "iac-platform"
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
