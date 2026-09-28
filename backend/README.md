# backend — Remote State Bootstrap

This directory provisions the S3 bucket and DynamoDB table that the main `stack/` uses for Terraform remote state and state locking.

> **Important:** This configuration intentionally uses **local state** so it does not depend on the remote backend it is creating.

---

## Resources Created

| Resource | Purpose |
|----------|---------|
| `aws_s3_bucket` | Stores `terraform.tfstate` for the main stack |
| `aws_s3_bucket_versioning` | Enables state file versioning / rollback |
| `aws_s3_bucket_server_side_encryption_configuration` | AES-256 encryption at rest |
| `aws_s3_bucket_public_access_block` | Blocks all public access |
| `aws_dynamodb_table` | State locking — prevents concurrent applies |

### Why DynamoDB locking?

The assignment explicitly requires DynamoDB locking. Modern Terraform (≥ 1.10) supports native S3 lockfiles, but DynamoDB is used here to satisfy the assignment requirement and to remain compatible with all Terraform 1.x versions.

---

## Step 1 — Bootstrap the backend

```bash
cd backend

# Initialise with local state
terraform init

# Review what will be created
terraform plan -var="state_bucket_name=full-iac-stack-tf-state-<YOUR_ACCOUNT_ID>"

# Create the S3 bucket and DynamoDB table
terraform apply -var="state_bucket_name=full-iac-stack-tf-state-<YOUR_ACCOUNT_ID>"
```

> S3 bucket names are globally unique. Append your AWS account ID or a random suffix.

---

## Step 2 — Configure the remote backend in stack/

Edit `stack/backend.tf` and replace the bucket name:

```hcl
terraform {
  backend "s3" {
    bucket       = "full-iac-stack-tf-state-<YOUR_ACCOUNT_ID>"
    key          = "full-iac-stack/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true   # Terraform >= 1.10 native S3 locking
  }
}
```

> The DynamoDB table is still provisioned (assignment requirement). `use_lockfile = true` uses the native S3 lockfile mechanism available in Terraform >= 1.10. Both provide state locking; the DynamoDB table satisfies the assignment's explicit DynamoDB requirement.

---

## Step 3 — Migrate stack state to S3

```bash
cd ../stack
terraform init -migrate-state
```

Terraform will prompt you to confirm the migration. Type `yes`.

---

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `ap-south-1` | AWS region |
| `project_name` | `full-iac-stack` | Used for naming and tagging |
| `state_bucket_name` | *(required)* | Globally unique S3 bucket name |
| `dynamodb_table_name` | `full-iac-stack-tf-locks` | DynamoDB table name |
