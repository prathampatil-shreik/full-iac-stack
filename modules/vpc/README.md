# VPC Module

Reusable Terraform module that provisions an AWS VPC with public and private subnets across two Availability Zones, an Internet Gateway, and a configurable NAT Gateway deployment.

## Architecture

### NAT disabled (`enable_nat_gateway = false`)

```
                        Internet
                           |
                  Internet Gateway
                           |
         ┌─────────────────┴─────────────────┐
  Public Subnet AZ-1               Public Subnet AZ-2

  Private Subnet AZ-1              Private Subnet AZ-2
  [no default outbound route]      [no default outbound route]
```

Private subnets have no default route. They cannot initiate outbound internet connections.

---

### Single NAT Gateway (`enable_nat_gateway = true`, `nat_gateway_mode = "single"`)

```
                        Internet
                           |
                  Internet Gateway
                           |
         ┌─────────────────┴─────────────────┐
  Public Subnet AZ-1               Public Subnet AZ-2
         |
   NAT Gateway (AZ-1)
         |                 |
  Private Subnet AZ-1   Private Subnet AZ-2
```

One NAT Gateway in AZ-1. Both private subnets route outbound traffic through it.
Lower cost. If AZ-1 becomes unavailable, both private subnets lose outbound internet access.
Suitable for development and non-critical workloads.

---

### Per-AZ NAT Gateway (`enable_nat_gateway = true`, `nat_gateway_mode = "per_az"`)

```
                        Internet
                           |
                  Internet Gateway
                           |
         ┌─────────────────┴─────────────────┐
  Public Subnet AZ-1               Public Subnet AZ-2
         |                                   |
  NAT Gateway (AZ-1)               NAT Gateway (AZ-2)
         |                                   |
  Private Subnet AZ-1              Private Subnet AZ-2
```

One NAT Gateway per AZ. Each private subnet routes through its own AZ-local NAT Gateway.
Each private subnet retains outbound internet access if the other AZ fails.
Suitable for production workloads with AZ fault-isolation requirements.

---

## Features

- VPC with configurable CIDR, DNS support and DNS hostnames enabled
- Two public subnets and two private subnets across two configurable AZs
- Internet Gateway for public subnet egress
- Three NAT Gateway modes: disabled, single, per-AZ
- Separate route table per private subnet
- Private subnets have no default internet route when NAT is disabled
- Input validation on all critical variables (see Validation section)
- Consistent resource tagging via `merge()`

## Resources Created

| Resource | Count | Description |
|----------|-------|-------------|
| `aws_vpc` | 1 | The VPC |
| `aws_internet_gateway` | 1 | Internet Gateway |
| `aws_subnet` (public) | 2 | Public subnets |
| `aws_subnet` (private) | 2 | Private subnets |
| `aws_eip` | 0, 1, or 2 | Elastic IPs for NAT Gateways |
| `aws_nat_gateway` | 0, 1, or 2 | NAT Gateways (mode-dependent) |
| `aws_route_table` (public) | 1 | Public route table with IGW default route |
| `aws_route_table` (private) | 2 | Per-subnet private route tables |
| `aws_route_table_association` | 4 | Subnet-to-route-table associations |

## Prerequisites

- Terraform >= 1.10.0
- AWS provider >= 6.0, < 7.0
- AWS credentials configured via `aws configure` or environment variables

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project_name` | Project name used in resource naming | `string` | — | yes |
| `environment` | Deployment environment (`dev` or `prod`) | `string` | — | yes |
| `vpc_cidr` | IPv4 CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| `public_subnet_cidrs` | Exactly two public subnet CIDRs | `list(string)` | — | yes |
| `private_subnet_cidrs` | Exactly two private subnet CIDRs | `list(string)` | — | yes |
| `availability_zones` | Exactly two distinct AZ names | `list(string)` | — | yes |
| `enable_nat_gateway` | Whether to create NAT Gateway resources | `bool` | `true` | no |
| `nat_gateway_mode` | NAT deployment mode: `single` or `per_az` | `string` | `"single"` | no |
| `tags` | Map of tags applied to all resources | `map(string)` | `{}` | no |

## Validation

The following checks are enforced at `terraform validate` / plan time:

| Variable | What is checked |
|----------|----------------|
| `project_name` | Matches `^[a-zA-Z0-9][a-zA-Z0-9-]{2,39}$` — 3 to 40 characters, letters, numbers and hyphens |
| `environment` | Must be exactly `dev` or `prod` |
| `vpc_cidr` | Must be a syntactically valid IPv4 CIDR (`can(cidrnetmask(...))`) |
| `public_subnet_cidrs` | Exactly 2 values, each a valid IPv4 CIDR, all values distinct |
| `private_subnet_cidrs` | Exactly 2 values, each a valid IPv4 CIDR, all values distinct |
| `availability_zones` | Exactly 2 values, each non-empty, all values distinct |
| `nat_gateway_mode` | Must be `single` or `per_az` |

### Known validation limitations

Terraform's built-in expression language does not include a `cidrcontains()` function or subnet overlap detection. The validations above check syntax, count and string distinctness only. They do **not** verify:

- That subnet CIDRs fall inside the VPC CIDR
- That public and private subnets do not overlap with each other

Supplying subnet CIDRs outside the VPC CIDR or overlapping subnets will pass `terraform validate` but will be rejected by the AWS API at apply time with a clear error message.

CIDR containment and overlap testing is covered in the Terratest integration tests (Stage 3).

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | ID of the VPC |
| `vpc_cidr_block` | CIDR block of the VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `public_route_table_id` | ID of the public route table |
| `private_route_table_ids` | List of private route table IDs (one per private subnet) |
| `internet_gateway_id` | ID of the Internet Gateway |
| `nat_gateway_id` | First NAT Gateway ID, or `null` when NAT is disabled |
| `nat_gateway_ids` | List of all NAT Gateway IDs (empty list when NAT is disabled) |

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
  nat_gateway_mode     = "single"

  tags = {
    Project   = "iac-platform"
    ManagedBy = "Terraform"
  }
}
```

## Cost Considerations

| Configuration | NAT Gateways | Approx. hourly charge |
|---------------|-------------|----------------------|
| `enable_nat_gateway = false` | 0 | $0.00 |
| `nat_gateway_mode = "single"` | 1 | ~$0.045/hr |
| `nat_gateway_mode = "per_az"` | 2 | ~$0.090/hr |

Data processing charge applies in addition: ~$0.045 per GB through each NAT Gateway.

- Use `enable_nat_gateway = false` for `terraform validate` and `terraform plan` testing — no NAT Gateway charges
- Use `nat_gateway_mode = "single"` for development environments to minimise cost
- Use `nat_gateway_mode = "per_az"` for production environments where AZ fault isolation is required

VPC, subnets, Internet Gateway and route tables have no hourly charge.

## Security Considerations

- Private subnets have no inbound internet route under any configuration
- When `enable_nat_gateway = false`, private subnets also have no outbound internet route
- `map_public_ip_on_launch = true` is set only on public subnets
- Place load balancers in public subnets; place application workloads and databases in private subnets

## Validation Commands

```powershell
# Format all files in the module
terraform fmt -recursive .\modules\vpc

# Confirm no further formatting changes are needed
terraform fmt -check -recursive .\modules\vpc

# Validate the example (no AWS credentials required for validate)
cd modules\vpc\examples\basic
terraform init
terraform validate

# Return to repo root
cd E:\Shreik\iac-platform
```

> `terraform validate` does not contact AWS and does not require credentials.
> `terraform plan` requires valid AWS credentials because the example uses
> `data "aws_availability_zones"` which calls the AWS API.

## Cleanup

```powershell
cd modules\vpc\examples\basic
terraform destroy
```

Destroying a stack that includes a NAT Gateway will also release the associated Elastic IP.
