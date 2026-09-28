# modules/network

Manages the networking layer for the full-iac-stack project inside the **existing default VPC**.

## VPC Quota Adaptation

Due to the AWS account VPC quota (maximum 5 VPCs), this project was adapted to use the **existing default VPC** rather than creating a new one. Terraform discovers the default VPC and its default public subnets via **data sources** and does not create or modify them.

Terraform continues to provision all project-specific private networking resources inside the default VPC.

## What Terraform Manages vs What Already Exists

| Resource | Managed By | Notes |
|----------|-----------|-------|
| VPC (`172.31.0.0/16`) | Pre-existing (default VPC) | Discovered via `data "aws_vpc"` |
| Internet Gateway | Pre-existing (attached to default VPC) | Not created or modified |
| Default public subnets (×3) | Pre-existing | Discovered via `data "aws_subnet"` |
| Private app subnets (×2) | **Terraform** | Created in `172.31.100.0/24`, `172.31.101.0/24` |
| Private DB subnets (×2) | **Terraform** | Created in `172.31.110.0/24`, `172.31.111.0/24` |
| Elastic IP | **Terraform** | For NAT Gateway |
| NAT Gateway | **Terraform** | Placed in default public subnet (ap-south-1a) |
| Private app route table | **Terraform** | Routes `0.0.0.0/0` → NAT Gateway |
| Private DB route table | **Terraform** | No internet route |

## CIDR Non-Overlap Verification

Existing default subnets in `172.31.0.0/16`:

| Subnet | AZ | Range |
|--------|----|-------|
| `172.31.0.0/20` | ap-south-1b | `172.31.0.0` – `172.31.15.255` |
| `172.31.16.0/20` | ap-south-1c | `172.31.16.0` – `172.31.31.255` |
| `172.31.32.0/20` | ap-south-1a | `172.31.32.0` – `172.31.47.255` |

New Terraform-managed subnets (safe, no overlap):

| Subnet | AZ | Purpose |
|--------|----|---------|
| `172.31.100.0/24` | ap-south-1a | Private app 1 |
| `172.31.101.0/24` | ap-south-1b | Private app 2 |
| `172.31.110.0/24` | ap-south-1a | Private DB 1 |
| `172.31.111.0/24` | ap-south-1b | Private DB 2 |

## Architecture

```
Existing Default VPC (172.31.0.0/16) — pre-existing, not managed by Terraform
    │
    ├── Default Public Subnets (pre-existing) ← ALB, NAT Gateway
    │   ├── 172.31.32.0/20  ap-south-1a
    │   └── 172.31.0.0/20   ap-south-1b
    │
    ├── Private App Subnets (Terraform-managed) ← EC2 instances
    │   ├── 172.31.100.0/24  ap-south-1a  → NAT Gateway
    │   └── 172.31.101.0/24  ap-south-1b  → NAT Gateway
    │
    └── Private DB Subnets (Terraform-managed) ← RDS
        ├── 172.31.110.0/24  ap-south-1a  (no internet route)
        └── 172.31.111.0/24  ap-south-1b  (no internet route)
```

## Cost Note

A **single NAT Gateway** is used (~$0.045/hr + data transfer). For production, deploy one per AZ.

## Usage

```hcl
module "network" {
  source = "../modules/network"

  project_name             = "full-iac-stack"
  environment              = "dev"
  availability_zones       = ["ap-south-1a", "ap-south-1b"]
  private_app_subnet_cidrs = ["172.31.100.0/24", "172.31.101.0/24"]
  private_db_subnet_cidrs  = ["172.31.110.0/24", "172.31.111.0/24"]
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | Existing default VPC ID |
| `vpc_cidr` | Existing default VPC CIDR |
| `public_subnet_ids` | Existing default public subnet IDs (for ALB/NAT) |
| `private_app_subnet_ids` | Terraform-managed private app subnet IDs |
| `private_db_subnet_ids` | Terraform-managed private DB subnet IDs |
| `nat_gateway_id` | NAT Gateway ID |
