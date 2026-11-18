# IAC Platform — Production-Grade Terraform Module Library

A production-grade Infrastructure as Code platform built on AWS using reusable Terraform modules, Terratest, Policy-as-Code, OIDC CI/CD, drift detection and cost controls.

## Project Overview

This repository implements a modular Terraform architecture where each AWS concern is encapsulated in an independently versioned, reusable module. Environments (`dev`, `prod`) consume these modules as building blocks.

## Repository Structure

```
iac-platform/
├── modules/
│   ├── vpc/          # Networking — VPC, subnets, IGW, NAT Gateway
│   ├── compute/      # ECS Fargate + ALB
│   ├── database/     # RDS MySQL
│   └── storage/      # S3 bucket
├── envs/
│   ├── dev/          # Development environment root configuration (Stage 2)
│   └── prod/         # Production environment root configuration (Stage 2)
├── tests/            # Terratest integration tests (Stage 2)
├── policy/           # OPA / Sentinel policy-as-code (Stage 3)
├── .github/
│   └── workflows/    # GitHub Actions OIDC CI/CD pipelines (Stage 4)
└── docs/
    └── evidence/     # Assignment evidence artefacts
```

## Modules

### VPC Module (`modules/vpc`)

Provisions a complete AWS networking foundation.

| Resource | Purpose |
|----------|---------|
| VPC | Isolated network with DNS enabled |
| Public Subnets (x2) | For load balancers and NAT Gateway |
| Private Subnets (x2) | For application workloads and databases |
| Internet Gateway | Public subnet internet access |
| NAT Gateway + EIP | Private subnet outbound internet access (optional) |
| Route Tables | Separate public and private routing |

### Compute Module (`modules/compute`)

Provisions an ECS Fargate service behind an Application Load Balancer.

| Resource | Purpose |
|----------|---------|
| ECS Cluster | Fargate compute cluster |
| ECS Task Definition | Container specification |
| ECS Service | Manages desired task count |
| Application Load Balancer | Public-facing HTTP entry point |
| ALB Target Group + Listener | Routes traffic to ECS tasks |
| Security Groups | ALB and ECS network isolation |
| IAM Task Execution Role | Least-privilege ECS permissions |
| CloudWatch Log Group | Container log aggregation |

### Database Module (`modules/database`)

Provisions a private Amazon RDS MySQL instance.

| Resource | Purpose |
|----------|---------|
| RDS MySQL Instance | Managed relational database |
| DB Subnet Group | Multi-AZ private subnet placement |
| Security Group | Restricts access to application SG only |

### Storage Module (`modules/storage`)

Provisions a secure, private Amazon S3 bucket.

| Resource | Purpose |
|----------|---------|
| S3 Bucket | Object storage |
| Versioning | Object version history |
| SSE-S3 Encryption | At-rest encryption |
| Public Access Block | Prevents all public access |
| Ownership Controls | Disables ACLs, enforces bucket owner |

## Module Relationships

```
                    ┌─────────────┐
                    │  VPC Module │
                    │  vpc_id     │
                    │  subnet_ids │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
     ┌────────▼──────┐     │    ┌───────▼──────┐
     │Compute Module │     │    │Storage Module│
     │  ALB + ECS    │     │    │  S3 Bucket   │
     │  ecs_sg_id ───┼─────┼──► │              │
     └───────────────┘     │    └──────────────┘
                           │
                  ┌────────▼──────┐
                  │Database Module│
                  │  RDS MySQL    │
                  └───────────────┘
```

The Compute module's `ecs_security_group_id` output is passed as `allowed_security_group_id` to the Database module, granting ECS tasks database access.

## Prerequisites

- Terraform >= 1.10.0
- AWS CLI configured (`aws configure`)
- AWS provider 6.x
- Git

## Quick Start — Validate a Module

```powershell
# Example: validate the VPC module example
cd modules\vpc\examples\basic
terraform init
terraform validate
terraform plan -var="enable_nat_gateway=false"
```

## Cost Controls

- Do not run `terraform apply` without reviewing the plan output
- Set `enable_nat_gateway = false` during VPC validation (~$0.045/hr saving)
- Set `desired_count = 0` to stop ECS tasks without destroying infrastructure
- Run `terraform destroy` after each development session for RDS instances
- RDS and NAT Gateway are the primary cost drivers in this architecture

## Security Principles

- All application workloads run in private subnets
- Security groups follow least-privilege (no `0.0.0.0/0` ingress to application tiers)
- Database passwords are never hardcoded — supplied via `TF_VAR_db_password`
- S3 buckets block all public access
- IAM roles use AWS managed policies scoped to their service

## Stages

| Stage | Description | Status |
|-------|-------------|--------|
| 1 | Reusable module design and implementation | ✅ Complete |
| 2 | Environment integration (`envs/dev`, `envs/prod`) | Pending |
| 3 | Policy-as-Code (OPA/Sentinel) | Pending |
| 4 | OIDC CI/CD (GitHub Actions) | Pending |
| 5 | Drift detection and cost controls | Pending |
