# Database Module

Reusable Terraform module that provisions a private Amazon RDS MySQL instance with encryption, automated backups, and network access restricted to a specified application security group.

## Architecture

```
Private Subnet AZ-1          Private Subnet AZ-2
       |                              |
       â””â”€â”€â”€â”€â”€â”€â”€â”€ DB Subnet Group â”€â”€â”€â”€â”€â”˜
                       |
              RDS MySQL Instance
              (storage_encrypted = true)
              (publicly_accessible = false)
                       |
              DB Security Group
              (ingress: app SG only)
```

## Features

- RDS MySQL 8.0 in private subnets
- Storage encryption enabled by default (`storage_encrypted = true`)
- Public accessibility disabled
- Automated backups with configurable retention
- Storage autoscaling with configurable maximum
- Configurable Multi-AZ deployment
- Database security group restricted to a single application security group
- Sensitive password variable â€” never stored in state in plaintext outputs
- Configurable deletion protection and final snapshot behaviour

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_db_subnet_group` | Subnet group spanning private subnets |
| `aws_security_group` | Database security group |
| `aws_security_group_rule` (x1) | Ingress from app SG only |
| `aws_db_instance` | RDS MySQL instance |

## Prerequisites

- Terraform >= 1.10.0
- AWS provider >= 6.0, < 7.0
- An existing VPC with at least two private subnets
- An application security group whose ID will be granted database access

## Verifying Supported MySQL Versions

Before deploying, verify the MySQL versions available in your region:

```powershell
aws rds describe-db-engine-versions --engine mysql --region us-east-1 `
  --query "DBEngineVersions[].EngineVersion" --output table
```

This module uses `engine_version = "8.0"` which is a major version prefix. AWS will select the latest `8.0.x` patch automatically.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project_name` | Project name used in resource naming | `string` | â€” | yes |
| `environment` | Deployment environment (`dev` or `prod`) | `string` | â€” | yes |
| `vpc_id` | VPC ID for the database security group | `string` | â€” | yes |
| `private_subnet_ids` | Private subnet IDs for the DB subnet group (min 2) | `list(string)` | â€” | yes |
| `allowed_security_group_id` | Security group ID allowed to connect to the DB | `string` | â€” | yes |
| `db_name` | Initial database name | `string` | â€” | yes |
| `db_username` | Master username | `string` | â€” | yes |
| `db_password` | Master password (sensitive) | `string` | â€” | yes |
| `instance_class` | RDS instance class | `string` | `"db.t3.micro"` | no |
| `allocated_storage` | Initial storage in GiB | `number` | `20` | no |
| `max_allocated_storage` | Maximum autoscaling storage in GiB | `number` | `100` | no |
| `backup_retention_period` | Backup retention in days (0â€“35) | `number` | `7` | no |
| `multi_az` | Enable Multi-AZ deployment | `bool` | `false` | no |
| `db_port` | Database port | `number` | `3306` | no |
| `deletion_protection` | Enable deletion protection | `bool` | `false` | no |
| `skip_final_snapshot` | Skip final snapshot on destroy | `bool` | `true` | no |
| `tags` | Map of tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `db_instance_identifier` | RDS instance identifier |
| `db_endpoint` | Connection endpoint (host:port) |
| `db_port` | Database port |
| `db_name` | Initial database name |
| `db_subnet_group_name` | DB subnet group name |
| `db_security_group_id` | Database security group ID |

## Example Usage

```hcl
module "database" {
  source = "./modules/database"

  project_name              = "iac-platform"
  environment               = "dev"
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  allowed_security_group_id = module.compute.ecs_security_group_id

  db_name     = "appdb"
  db_username = "dbadmin"
  db_password = var.db_password  # supplied via TF_VAR_db_password

  tags = {
    Project   = "iac-platform"
    ManagedBy = "Terraform"
  }
}
```

## Security Considerations

- Never hardcode `db_password` â€” supply it via `TF_VAR_db_password` or AWS Secrets Manager
- The database password is marked `sensitive = true` and is not exposed in outputs
- `publicly_accessible = false` ensures the instance has no public endpoint
- Database security group allows inbound only from the specified application security group; no outbound rules are defined (RDS does not initiate outbound connections)
- Set `deletion_protection = true` and `skip_final_snapshot = false` in production

## Cost Considerations

| Resource | Estimated Cost |
|----------|---------------|
| db.t3.micro (single-AZ) | ~$0.017/hr |
| db.t3.micro (Multi-AZ) | ~$0.034/hr |
| Storage gp3 (20 GiB) | ~$0.023/GiB/month |
| Automated backups (within retention) | Free up to DB size |

RDS instances incur charges from the moment they are created. Run `terraform destroy` when not in use during development.

## Validation

```powershell
cd modules\database\examples\basic
terraform init
terraform validate
# Set password via environment variable before plan
$env:TF_VAR_db_password = "REPLACE_WITH_A_SECURE_PASSWORD"
terraform plan -var="vpc_id=vpc-xxx" -var='private_subnet_ids=["subnet-a","subnet-b"]' -var="allowed_security_group_id=sg-xxx"
```

## Cleanup

```powershell
terraform destroy
```
