# stack — Root Terraform Configuration

This directory composes the `network`, `compute`, and `database` modules into a complete deployable stack.

## VPC Quota Adaptation

Due to the AWS account VPC quota (maximum 5 VPCs), this project uses the **existing default VPC** (`vpc-0540f855b0f697698`, `172.31.0.0/16`) rather than creating a new one. The VPC and its default public subnets are discovered via Terraform data sources. Terraform provisions all project-specific private networking, security groups, compute, database, load balancer, and monitoring resources inside the default VPC.

## Prerequisites

- Terraform >= 1.6.0
- AWS CLI configured (`aws configure` or environment variables)
- Backend bootstrap completed (see `../backend/README.md`)
- ECR image pushed: `925213028316.dkr.ecr.ap-south-1.amazonaws.com/full-iac-stack-app:1.0.0`

## First-Time Setup

### 1. Bootstrap the remote backend

```bash
cd ../backend
terraform init
terraform apply -var="state_bucket_name=full-iac-stack-tf-state-925213028316"
```

### 2. Configure variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — do NOT add db_password here
export TF_VAR_db_password="your-secure-password"
```

### 3. Initialise

```bash
cd ../stack
terraform init
```

## Terraform Workflow

```bash
# Format
terraform fmt -recursive

# Validate
terraform validate

# Plan — review before applying
terraform plan

# Apply — only after reviewing the plan
terraform apply

# Destroy — only when intentionally tearing down
terraform destroy
```

## Module Reuse — Staging Environment

To deploy a staging environment using the same modules, change these variables:

```hcl
environment              = "staging"
vpc_cidr                 = "10.1.0.0/16"
public_subnet_cidrs      = ["10.1.1.0/24", "10.1.2.0/24"]
private_app_subnet_cidrs = ["10.1.11.0/24", "10.1.12.0/24"]
private_db_subnet_cidrs  = ["10.1.21.0/24", "10.1.22.0/24"]
```

No module code changes are required. The same three modules are reused.

## Outputs

After `terraform apply`, the following outputs are available:

| Output | Description |
|--------|-------------|
| `application_url` | `http://<alb-dns>` |
| `health_check_url` | `http://<alb-dns>/health` |
| `alb_dns_name` | ALB DNS name |
| `instance_ids` | EC2 instance IDs |
| `db_endpoint` | RDS endpoint |
