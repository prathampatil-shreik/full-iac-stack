# full-iac-stack

Full Infrastructure-as-Code stack — Spring Boot application deployed to AWS EC2 behind an Application Load Balancer, with RDS MySQL, CloudWatch monitoring, remote Terraform state in S3, and a GitHub Actions CI/CD pipeline.

---

## Architecture

> **VPC Quota Note:** Due to the AWS account VPC quota (maximum 5 VPCs), this project uses the existing default VPC (`172.31.0.0/16`) rather than creating a new one. Terraform discovers the default VPC and its public subnets via data sources and provisions all project-specific private networking, security groups, compute, database, load balancer, and monitoring resources inside it.

```
Existing Default VPC (172.31.0.0/16) — pre-existing
    │
    ▼ HTTP :80
Application Load Balancer  (existing default public subnets)
    │
    ▼ HTTP :8080
EC2 × 2  (Terraform-managed private app subnets: 172.31.100.0/24, 172.31.101.0/24)
    │
    ▼ MySQL :3306
RDS MySQL  (Terraform-managed private DB subnets: 172.31.110.0/24, 172.31.111.0/24)
```

**Region:** us-east-1 (N. Virginia)  
**VPC:** 10.0.0.0/16

---

## Folder Structure

```
full-iac-stack/
├── application/          Spring Boot REST application
├── backend/              S3 + DynamoDB remote state bootstrap
├── modules/
│   ├── network/          VPC, subnets, IGW, NAT Gateway, routing
│   ├── compute/          EC2, ALB, IAM role, security groups
│   └── database/         RDS MySQL, DB subnet group
├── stack/                Root Terraform — composes all modules
├── pipeline/
│   └── terraform.yml     GitHub Actions workflow
└── docs/
    ├── iac-report.md
    ├── research.md
    └── runbook.md
```

---

## Prerequisites

- Terraform >= 1.6.0
- AWS CLI configured for us-east-1
- Docker (for application builds)
- Java 17 + Maven (for application builds)
- GitHub repository (for pipeline)

---

## Step 1 — Bootstrap Remote State

```bash
cd backend
terraform init
terraform apply -var="state_bucket_name=full-iac-stack-tf-state-<YOUR_ACCOUNT_ID>"
```

---

## Step 2 — Configure the Stack Backend

Edit `stack/backend.tf` and replace the bucket name with the one created above.

```bash
cd stack
terraform init -migrate-state
```

---

## Step 3 — Configure Variables

```bash
cp stack/terraform.tfvars.example stack/terraform.tfvars
# Edit terraform.tfvars — do NOT add db_password

export TF_VAR_db_password="your-secure-password"
```

---

## Step 4 — Deploy

```bash
cd stack
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

---

## Terraform Commands Reference

| Command | Purpose |
|---------|---------|
| `terraform fmt -recursive` | Format all .tf files |
| `terraform init` | Initialise providers and backend |
| `terraform validate` | Validate configuration syntax |
| `terraform plan` | Dry run — shows what will change |
| `terraform apply` | Apply the plan |
| `terraform destroy` | Destroy all managed resources |
| `terraform output` | Show output values |

---

## Application Endpoints (after apply)

```bash
ALB_DNS=$(terraform -chdir=stack output -raw alb_dns_name)

curl http://$ALB_DNS/
curl http://$ALB_DNS/health
curl http://$ALB_DNS/api/info
curl http://$ALB_DNS/actuator/health
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TF_VAR_db_password` | *(required)* | RDS master password — never commit |
| `APP_ENVIRONMENT` | `dev` | Passed to the Docker container |
| `APP_VERSION` | `1.0.0` | Passed to the Docker container |

---

## Module Reuse — Staging

To deploy a staging environment, change these variables in `terraform.tfvars`:

```hcl
environment              = "staging"
private_app_subnet_cidrs = ["172.31.120.0/24", "172.31.121.0/24"]
private_db_subnet_cidrs  = ["172.31.130.0/24", "172.31.131.0/24"]
```

No module code changes are required. The same three modules are reused.

---

## GitHub Actions Setup

### 1. Create the OIDC IAM Role in AWS

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
    },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
      },
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:<YOUR_GITHUB_ORG>/<YOUR_REPO>:*"
      }
    }
  }]
}
```

Attach a policy granting the role permissions to manage VPC, EC2, RDS, S3, DynamoDB, IAM, CloudWatch, and ELB resources.

### 2. Add GitHub Secrets

| Secret | Value |
|--------|-------|
| `AWS_OIDC_ROLE_ARN` | ARN of the IAM role created above |
| `TF_VAR_DB_PASSWORD` | RDS master password |

### 3. Push to GitHub

The pipeline triggers automatically on pull requests and pushes to main.

---

## Drift Detection

1. Manually add a tag to the VPC in the AWS Console.
2. Run `terraform plan` — Terraform detects the difference.
3. Run `terraform apply` — the tag is removed and the resource returns to the defined state.

---

## Resource Replacement Demonstration

1. Change `instance_type` from `t3.micro` to `t3.small` in `terraform.tfvars`.
2. Run `terraform plan` — look for `-/+` indicating destroy + recreate.
3. Revert the change if replacement is not intended.

---

## Destroy and Recreate

```bash
# Destroy
cd stack
terraform destroy

# Recreate
terraform apply
```

**RDS note:** `deletion_protection = false` and `skip_final_snapshot = true` are set for this test environment. For production, enable deletion protection and take a final snapshot before destroying.

---

## Security

- Database password: `sensitive = true`, supplied via `TF_VAR_db_password` only.
- S3 state: versioning + AES-256 encryption + public access blocked.
- Port 8080: only reachable from ALB security group.
- Port 3306: only reachable from application security group.
- GitHub Actions: OIDC only — no long-lived AWS keys.
- `.gitignore`: excludes `*.tfstate`, `.terraform/`, `terraform.tfvars`.

---

## Cost Considerations

| Resource | Approx. |
|----------|---------|
| 2 × t3.micro EC2 | ~$0.042/hr |
| 1 × ALB | ~$0.008/hr |
| 1 × NAT Gateway | ~$0.045/hr |
| 1 × db.t3.micro RDS | ~$0.017/hr |

Run `terraform destroy` when not in use to avoid ongoing charges.

---

## Troubleshooting

**`terraform init` fails — backend bucket not found:**  
Run the backend bootstrap first: `cd backend && terraform apply`.

**EC2 instances unhealthy in ALB:**  
Check that the Docker container started. SSH is not available (private subnet). Use AWS Systems Manager Session Manager or check EC2 instance system logs in the AWS Console.

**`Error acquiring the state lock`:**  
Another apply is running, or a previous apply crashed. Check the DynamoDB table for a stale lock item and delete it manually if confirmed stale.

**`db_password` not set:**  
```bash
export TF_VAR_db_password="your-secure-password"
```
