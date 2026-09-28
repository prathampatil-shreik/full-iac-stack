# Full Infrastructure-as-Code — Assignment Report

**Project:** Full Infrastructure-as-Code — Define the Whole Application Stack in Terraform  
**Application:** full-iac-stack-app  
**Region:** us-east-1 (N. Virginia)  
**Author:** [Your Name]  
**Date:** [Date]

---

## 1. Executive Summary

This project implements a complete Infrastructure-as-Code stack using Terraform on AWS. A Spring Boot REST application is containerised with Docker, pushed to Amazon ECR, and deployed to EC2 instances behind an Application Load Balancer. All infrastructure is defined in reusable Terraform modules with remote state stored in S3 and state locking via DynamoDB. A GitHub Actions pipeline automates plan and apply using OIDC authentication.

---

## 2. Objectives

- Define all AWS infrastructure in Terraform with no manual console provisioning.
- Use reusable modules for network, compute, and database layers.
- Store Terraform state remotely in S3 with DynamoDB locking.
- Deploy the application to EC2 instances running Docker.
- Expose the application through an Application Load Balancer.
- Automate the Terraform workflow with GitHub Actions using OIDC.
- Demonstrate drift detection, resource replacement, and destroy/recreate.

---

## 3. Architecture

> **VPC Quota Adaptation:** Due to the AWS account VPC quota (maximum 5 VPCs), this project was adapted to use the existing default VPC while Terraform continues to provision the project-specific private networking, security groups, compute, database, load balancer, and monitoring resources.

```
Existing Default VPC (172.31.0.0/16) — pre-existing, not created by Terraform
    │
    ▼ HTTP :80
Application Load Balancer (existing default public subnets)
    │
    ▼ HTTP :8080
EC2 Instances × 2 (Terraform-managed private app subnets)
    │
    ▼ MySQL :3306
RDS MySQL (Terraform-managed private DB subnets)
```

**Region:** us-east-1 (N. Virginia)  
**VPC:** `172.31.0.0/16` (existing default VPC `vpc-0540f855b0f697698`)

| Resource | CIDR | Managed By |
|----------|------|------------|
| Default public subnet us-east-1a | `172.31.32.0/20` | Pre-existing |
| Default public subnet us-east-1b | `172.31.0.0/20` | Pre-existing |
| Private app subnet us-east-1a | `172.31.100.0/24` | Terraform |
| Private app subnet us-east-1b | `172.31.101.0/24` | Terraform |
| Private DB subnet us-east-1a | `172.31.110.0/24` | Terraform |
| Private DB subnet us-east-1b | `172.31.111.0/24` | Terraform |

---

## 4. Terraform Repository Structure

```
full-iac-stack/
├── application/          Spring Boot application
├── backend/              S3 + DynamoDB bootstrap
├── modules/
│   ├── network/          VPC, subnets, IGW, NAT, routing
│   ├── compute/          EC2, ALB, IAM, security groups
│   └── database/         RDS MySQL, DB subnet group
├── stack/                Root configuration — composes modules
├── pipeline/             GitHub Actions workflow
└── docs/                 Reports, research, runbook
```

[SCREENSHOT 05 — Terraform Repository Structure]  
*Shows the full folder tree in the IDE or file explorer, proving the modular structure.*

---

## 5. Network Module

The network module uses the existing default VPC via a Terraform data source and creates four project-specific private subnets across two AZs. A single NAT Gateway provides outbound internet access for private application subnets. Database subnets have no internet route. The default VPC's Internet Gateway is pre-existing and not managed by Terraform.

[SCREENSHOT 10 — VPC]  
*AWS Console → VPC → Your VPCs. Shows the existing default VPC with CIDR 172.31.0.0/16.*

[SCREENSHOT 11 — Subnets]  
*AWS Console → VPC → Subnets. Shows the four Terraform-managed private subnets alongside the existing default public subnets.*

[SCREENSHOT 12 — Route Tables]  
*AWS Console → VPC → Route Tables. Shows private-app and private-db route tables created by Terraform.*

---

## 6. Compute Module

Two EC2 instances run in private application subnets. Each instance pulls the Docker image from ECR on first boot using an IAM instance role. The container runs with `--restart always`.

[SCREENSHOT 14 — EC2 Instances]  
*AWS Console → EC2 → Instances. Shows two running instances in private subnets.*

---

## 7. Database Module

An RDS MySQL 8.0 instance runs in private database subnets. It is not publicly accessible. Port 3306 is only reachable from the application security group.

[SCREENSHOT 18 — RDS]  
*AWS Console → RDS → Databases. Shows the RDS instance status as Available.*

---

## 8. Load Balancer

An internet-facing Application Load Balancer in public subnets forwards HTTP/80 traffic to EC2 instances on port 8080. The health check uses `GET /health`.

[SCREENSHOT 15 — ALB]  
*AWS Console → EC2 → Load Balancers. Shows the ALB in Active state.*

[SCREENSHOT 16 — ALB Target Health]  
*AWS Console → EC2 → Target Groups → Targets. Shows both targets as Healthy.*

[SCREENSHOT 17 — Application via ALB]  
*Browser showing `http://<alb-dns>/health` returning `{"status":"healthy",...}`.*

---

## 9. Security Groups

| Security Group | Inbound | Outbound |
|---------------|---------|---------|
| ALB SG | TCP 80 from 0.0.0.0/0 | All |
| App SG | TCP 8080 from ALB SG only | All |
| DB SG | TCP 3306 from App SG only | All |

[SCREENSHOT 13 — Security Groups]  
*AWS Console → EC2 → Security Groups. Shows all three security groups with correct rules.*

---

## 10. CloudWatch Monitoring

CloudWatch alarms monitor:
- EC2 CPU > 80%
- ALB unhealthy host count > 0
- RDS CPU > 80%
- RDS free storage < 2 GB

A CloudWatch dashboard (`full-iac-stack-dashboard`) visualises all four metrics.

[SCREENSHOT 19 — CloudWatch]  
*AWS Console → CloudWatch → Dashboards → full-iac-stack-dashboard.*

---

## 11. Remote State

Terraform state is stored in an S3 bucket with versioning, AES-256 encryption, and public access blocked.

[SCREENSHOT 20 — S3 Remote State]  
*AWS Console → S3 → full-iac-stack-tf-state bucket. Shows versioning enabled.*

[SCREENSHOT 21 — Terraform State File]  
*S3 bucket contents showing terraform.tfstate object.*

---

## 12. State Locking

DynamoDB provides state locking. The table uses `LockID` as the partition key with PAY_PER_REQUEST billing.

[SCREENSHOT 22 — DynamoDB Lock Table]  
*AWS Console → DynamoDB → Tables → full-iac-stack-tf-locks.*

[SCREENSHOT 23 — Lock Acquired]  
*DynamoDB table items view during an active `terraform apply`, showing the LockID item.*

[SCREENSHOT 24 — Second Apply Blocked]  
*Terminal output showing "Error acquiring the state lock" when a second apply is attempted.*

---

## 13. Module Reuse

The same three modules are reused for staging by changing variable values only. Since the project uses the existing default VPC, staging uses different private subnet CIDRs within the same VPC:

```hcl
environment              = "staging"
private_app_subnet_cidrs = ["172.31.120.0/24", "172.31.121.0/24"]
private_db_subnet_cidrs  = ["172.31.130.0/24", "172.31.131.0/24"]
```

No module code is duplicated.

---

## 14. Terraform Plan and Apply Workflow

```bash
terraform fmt -recursive   # Format all files
terraform init             # Initialise providers and backend
terraform validate         # Validate configuration syntax
terraform plan             # Dry run — review before applying
terraform apply            # Apply after review
```

[SCREENSHOT 07 — terraform init]  
*Terminal showing successful `terraform init` output.*

[SCREENSHOT 08 — terraform validate]  
*Terminal showing `Success! The configuration is valid.`*

[SCREENSHOT 09 — terraform plan]  
*Terminal showing the plan output with resources to be created.*

---

## 15. GitHub Actions Pipeline

The pipeline runs on pull requests (plan only) and pushes to main (plan + apply). AWS credentials are provided via OIDC — no long-lived access keys are stored in GitHub.

[SCREENSHOT 25 — GitHub PR Plan]  
*GitHub pull request showing the Terraform plan posted as a PR comment.*

[SCREENSHOT 26 — GitHub Apply]  
*GitHub Actions run showing successful `terraform apply` on push to main.*

---

## 16. Security

- Database password supplied via `TF_VAR_db_password` — never committed to Git.
- `db_password` variable marked `sensitive = true`.
- S3 state bucket: versioning, AES-256 encryption, public access blocked.
- Port 8080 only reachable from ALB security group.
- Port 3306 only reachable from application security group.
- GitHub Actions uses OIDC — no `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` secrets.
- `.gitignore` excludes `*.tfstate`, `.terraform/`, `terraform.tfvars`.

---

## 17. Destroy and Recreate

```bash
# Destroy all resources
terraform destroy

# Recreate
terraform apply
```

**RDS note:** `deletion_protection = false` and `skip_final_snapshot = true` are set for this test environment to allow clean teardown. For production, set `deletion_protection = true` and take a final snapshot before destroying.

[SCREENSHOT 28 — terraform destroy]  
*Terminal showing `terraform destroy` plan output.*

[SCREENSHOT 29 — terraform recreate]  
*Terminal showing `terraform apply` recreating all resources.*

[SCREENSHOT 30 — Recreated Application]  
*Browser showing the application responding via the new ALB DNS name.*

---

## 18. Drift Detection

Since the default VPC is not managed by Terraform, drift is demonstrated on a Terraform-managed resource. The recommended target is one of the private subnets or security groups.

1. Manually add a tag (e.g. `Temp = manual-change`) to the private app subnet in the AWS Console.
2. Run `terraform plan`.
3. Terraform detects the difference and shows the tag change.
4. Run `terraform apply` to reconcile.
5. The subnet tag returns to the Terraform-defined state.

[SCREENSHOT 31 — Manual Drift Change]  
*AWS Console showing the manually added tag on the private app subnet.*

[SCREENSHOT 32 — Drift Detected]  
*`terraform plan` output showing `~ update in-place` for the subnet tags.*

[SCREENSHOT 33 — Drift Reconciled]  
*`terraform apply` output showing the tag corrected.*

---

## 19. Resource Replacement Demonstration

A resource replacement is triggered when a change to an immutable attribute forces destroy + recreate. In `terraform plan` output this appears as:

```
-/+ resource "aws_instance" "app" {
      ~ id = "i-0abc123" -> (known after apply) # forces replacement
    }
```

**Safe demonstration:** Change the `instance_type` from `t3.micro` to `t3.small` in `terraform.tfvars`. Run `terraform plan`. The plan will show `-/+` for the EC2 instances. Review the plan, then revert the change if the replacement is not intended.

[SCREENSHOT 27 — Resource Replacement Plan]  
*`terraform plan` output showing `-/+` for EC2 instances due to instance type change.*

---

## 20. Testing and Validation

After `terraform apply`:

```bash
# Get the ALB DNS name
terraform output application_url

# Test all endpoints
curl http://<alb-dns>/
curl http://<alb-dns>/health
curl http://<alb-dns>/api/info
curl http://<alb-dns>/actuator/health
```

Expected `/health` response:
```json
{"status":"healthy","application":"full-iac-stack-app","environment":"dev","version":"1.0.0","message":"Application is running successfully"}
```

---

## 21. Cost Considerations

| Resource | Approx. Cost |
|----------|-------------|
| 2 × t3.micro EC2 | ~$0.021/hr each |
| 1 × ALB | ~$0.008/hr + LCU |
| 1 × NAT Gateway | ~$0.045/hr + data |
| 1 × db.t3.micro RDS | ~$0.017/hr |
| S3 state bucket | Negligible |
| DynamoDB (PAY_PER_REQUEST) | Negligible |

**Total estimate:** ~$0.11/hr (~$80/month if left running).

Destroy the stack when not in use: `terraform destroy`.

---

## 22. Lessons Learned

- A single NAT Gateway reduces cost but creates a single point of failure for private subnet outbound traffic. Production workloads should use one NAT Gateway per AZ.
- The `sensitive = true` flag on `db_password` prevents accidental output but does not encrypt the value in the state file. S3 encryption and restricted IAM access are essential.
- `skip_final_snapshot = true` is convenient for test environments but must never be used in production.
- OIDC for GitHub Actions eliminates the risk of long-lived credential exposure entirely.

---

## 23. Future Improvements

- Add HTTPS (ACM certificate + ALB HTTPS listener).
- Enable RDS Multi-AZ for high availability.
- Add Auto Scaling Group instead of fixed EC2 count.
- Add WAF to the ALB.
- Integrate the Spring Boot application with RDS.
- Add CloudWatch log groups and structured application logging.
- Use Terraform workspaces or separate state files for staging.

---

## 24. Conclusion

This project demonstrates a complete, production-style Infrastructure-as-Code implementation using Terraform on AWS. All infrastructure is defined in reusable modules, state is managed remotely with locking, and the deployment pipeline uses secure OIDC authentication. The application is reachable through the ALB and the health endpoint is ready for ALB health checks.

---

## Screenshots Index

| # | Filename | What It Proves |
|---|----------|---------------|
| 01 | 01-local-application.png | Application running locally |
| 02 | 02-docker-image.png | Docker image built successfully |
| 03 | 03-ecr-repository.png | ECR repository exists |
| 04 | 04-ecr-image.png | Image pushed to ECR |
| 05 | 05-terraform-repository-structure.png | Modular folder structure |
| 06 | 06-network-module.png | Network module files |
| 07 | 07-terraform-init.png | Successful terraform init |
| 08 | 08-terraform-validate.png | Configuration is valid |
| 09 | 09-terraform-plan.png | Plan output before apply |
| 10 | 10-vpc.png | VPC created in AWS Console |
| 11 | 11-subnets.png | All six subnets created |
| 12 | 12-route-tables.png | Route tables configured |
| 13 | 13-security-groups.png | Security groups with correct rules |
| 14 | 14-ec2-instances.png | Two EC2 instances running |
| 15 | 15-alb.png | ALB active |
| 16 | 16-alb-target-health.png | Both targets healthy |
| 17 | 17-application-alb.png | Application responding via ALB |
| 18 | 18-rds.png | RDS instance available |
| 19 | 19-cloudwatch.png | CloudWatch dashboard |
| 20 | 20-s3-remote-state.png | S3 bucket with versioning |
| 21 | 21-terraform-state.png | State file in S3 |
| 22 | 22-dynamodb-lock.png | DynamoDB lock table |
| 23 | 23-lock-acquired.png | Lock item during apply |
| 24 | 24-second-apply-blocked.png | Concurrent apply blocked |
| 25 | 25-github-pr-plan.png | Plan in PR comment |
| 26 | 26-github-apply.png | Successful GitHub Actions apply |
| 27 | 27-resource-replacement-plan.png | -/+ in plan output |
| 28 | 28-terraform-destroy.png | Destroy plan |
| 29 | 29-terraform-recreate.png | Recreate apply |
| 30 | 30-recreated-application.png | Application working after recreate |
| 31 | 31-manual-drift-change.png | Manual tag change in console |
| 32 | 32-drift-detected.png | terraform plan detects drift |
| 33 | 33-drift-reconciled.png | terraform apply reconciles drift |
| 34 | 34-final-clean-account.png | Clean account after destroy |
