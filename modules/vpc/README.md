# VPC Module

Reusable Terraform module that provisions a production-grade AWS VPC with public and private subnets across two Availability Zones, an Internet Gateway, and an optional NAT Gateway.

## Architecture

```
                          Internet
                             |
                    Internet Gateway
                             |
          ┌──────────────────┴──────────────────┐
   Public Subnet AZ-1                   Public Subnet AZ-2
   (10.0.1.0/24)                        (10.0.2.0/24)
          |
     NAT Gateway (optional)
          |
          ├──────────────────┬──────────────────┐
   Private Subnet AZ-1              Private Subnet AZ-2
   (10.0.11.0/24)                   (10.0.12.0/24)
```

## Features

- VPC with configurable CIDR, DNS support and DNS hostnames enabled
- Two public subnets and two private subnets across two configurable AZs
- Internet Gateway for public subnet egress
- Optional single NAT Gateway for private subnet outbound internet access
- Separate route table per private subnet
- Public access blocked from private subnets when NAT is disabled
- Consistent resource tagging via `merge()`
- Input validation on CIDR blocks, list lengths and environment names

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_vpc` | The VPC |
| `aws_internet_gateway` | Internet Gateway attached to the VPC |
| `aws_subnet` (x2) | Public subnets |
| `aws_subnet` (x2) | Private subnets |
| `aws_eip` | Elastic IP for the NAT Gateway (conditional) |
| `aws_nat_gateway` | NAT Gateway in public subnet AZ-1 (conditional) |
| `aws_route_table` | Public route table with IGW default route |
| `aws_route_table` (x2) | Private route tables with optional NAT default route |
| `aws_route_table_association` (x4) | Subnet-to-route-table associations |

## Prerequisites

- Terraform >= 1.10.0
- AWS provider >= 6.0, < 7.0
- AWS credentials configured via `aws configure` or environment variables

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project_name` | Project name used in resource naming | `string` | — | yes |
| `environment` | Deployment environment (`dev` or `prod`) | `string` | — | yes |
| `vpc_cidr` | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| `public_subnet_cidrs` | List of exactly two public subnet CIDRs | `list(string)` | — | yes |
| `private_subnet_cidrs` | List of exactly two private subnet CIDRs | `list(string)` | — | yes |
| `availability_zones` | List of exactly two AZ names | `list(string)` | — | yes |
| `enable_nat_gateway` | Create a NAT Gateway for private subnet egress | `bool` | `true` | no |
| `tags` | Map of tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `public_route_table_id` | ID of the public route table |
| `private_route_table_ids` | List of private route table IDs |
| `internet_gateway_id` | ID of the Internet Gateway |
| `nat_gateway_id` | ID of the NAT Gateway (null when disabled) |

## Example Usage

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "./modules/vpc"

  project_name         = "iac-platform"
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  enable_nat_gateway   = true

  tags = {
    Project   = "iac-platform"
    ManagedBy = "Terraform"
  }
}
```

## Security Considerations

- Private subnets have no direct inbound or outbound internet route
- When `enable_nat_gateway = false`, private subnets are fully isolated from the internet
- Only place load balancers and bastion hosts in public subnets
- ECS tasks, RDS instances and other application resources belong in private subnets

## Cost Considerations

| Resource | Estimated Cost |
|----------|---------------|
| NAT Gateway | ~$0.045/hr + $0.045/GB data processed |
| Elastic IP (attached to NAT) | Included in NAT Gateway cost |
| Elastic IP (unattached) | ~$0.005/hr |
| VPC, Subnets, IGW, Route Tables | Free |

Set `enable_nat_gateway = false` during development and validation to avoid NAT Gateway charges.

## Validation

```powershell
cd modules\vpc\examples\basic
terraform init
terraform validate
terraform plan -var="enable_nat_gateway=false"
```

## Cleanup

```powershell
terraform destroy -var="enable_nat_gateway=false"
```
