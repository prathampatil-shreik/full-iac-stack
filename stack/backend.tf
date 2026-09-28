# ---------------------------------------------------------------------------
# Remote Terraform backend
#
# State is stored in S3 with versioning and encryption enabled.
# Terraform state locking is provided by the DynamoDB table below.
# ---------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket         = "full-iac-stack-tf-state-925213028316-us-east1"
    key            = "full-iac-stack/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "full-iac-stack-tf-locks"
  }
}
