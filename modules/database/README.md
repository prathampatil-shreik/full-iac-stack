# modules/database

Provisions an Amazon RDS MySQL instance in private database subnets.

## Resources

| Resource | Description |
|----------|-------------|
| `aws_db_subnet_group` | Subnet group using private DB subnets |
| `aws_security_group` (db) | Allows MySQL/3306 from app SG only |
| `aws_db_instance` | RDS MySQL 8.0 instance |

## Security Design

```
Application EC2 (app-sg)
        │
        ▼ port 3306 only
   RDS MySQL (db-sg)
   (no public access)
   (no internet route on subnet)
```

The database is **never** publicly accessible. `0.0.0.0/0` is never allowed to port 3306.

## Test Account Settings

| Setting | Value | Reason |
|---------|-------|--------|
| `deletion_protection` | `false` | Allows clean `terraform destroy` |
| `skip_final_snapshot` | `true` | No retained snapshot on destroy |
| `multi_az` | `false` | Cost reduction |
| `instance_class` | `db.t3.micro` | Cost reduction |

> For production: set `deletion_protection = true`, `multi_az = true`, and `skip_final_snapshot = false`.

## Password Security

The `db_password` variable is marked `sensitive = true`. It will never appear in Terraform output or logs. Supply it via:

```bash
# Environment variable (recommended for local use)
export TF_VAR_db_password="your-secure-password"
terraform plan

# Or via -var flag (not recommended — appears in shell history)
terraform plan -var="db_password=your-secure-password"
```

**Never commit a real password to Git.**

## Usage

```hcl
module "database" {
  source = "../modules/database"

  project_name          = "full-iac-stack"
  environment           = "dev"
  vpc_id                = module.network.vpc_id
  private_db_subnet_ids = module.network.private_db_subnet_ids
  app_security_group_id = module.compute.compute_security_group_id
  db_name               = "appdb"
  db_username           = "admin"
  db_password           = var.db_password
  db_instance_class     = "db.t3.micro"
  db_allocated_storage  = 20
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `db_instance_identifier` | RDS identifier |
| `db_endpoint` | host:port endpoint |
| `db_port` | Port (3306) |
| `db_security_group_id` | DB security group ID |
| `db_subnet_group_name` | DB subnet group name |
