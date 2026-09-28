# Research — Infrastructure as Code

## 1. Infrastructure as Code vs Manual AWS Console Provisioning

Manual provisioning through the AWS Console is error-prone, undocumented, and not repeatable. Each environment must be recreated by hand, and there is no audit trail of what was changed or when.

Infrastructure as Code (IaC) defines infrastructure in version-controlled files. Every resource, configuration, and dependency is explicit. Changes go through code review. Environments are reproducible.

| Aspect | Manual Console | IaC (Terraform) |
|--------|---------------|-----------------|
| Repeatability | None | Full |
| Audit trail | CloudTrail only | Git history |
| Drift detection | Manual | `terraform plan` |
| Environment parity | Difficult | Guaranteed |
| Rollback | Manual | `git revert` + apply |

Reference: https://docs.aws.amazon.com/whitepapers/latest/introduction-devops-aws/infrastructure-as-code.html

---

## 2. Advantages of Terraform

- **Provider-agnostic** — supports AWS, Azure, GCP, and hundreds of other providers from a single tool.
- **Declarative** — you describe the desired state; Terraform determines the actions required.
- **Dependency graph** — Terraform automatically resolves resource dependencies and parallelises independent operations.
- **Plan before apply** — `terraform plan` shows exactly what will change before any modification is made.
- **State management** — Terraform tracks real infrastructure in a state file, enabling drift detection and incremental updates.
- **Module system** — reusable, composable infrastructure components.

Reference: https://developer.hashicorp.com/terraform/intro

---

## 3. Terraform Modules

A module is a directory of `.tf` files that encapsulates a set of related resources. Modules accept input variables and expose outputs, making them reusable across environments.

```
modules/
  network/    ← VPC, subnets, routing
  compute/    ← EC2, ALB, security groups
  database/   ← RDS, DB subnet group
```

The root `stack/` calls each module, passing outputs from one as inputs to the next. The same module code is reused for `dev` and `staging` by changing variable values only.

Reference: https://developer.hashicorp.com/terraform/language/modules

---

## 4. Terraform Plan vs Terraform Apply

`terraform plan` performs a dry run. It reads the current state, queries the real AWS API, and computes the difference. No resources are created or modified.

`terraform apply` executes the changes shown in the plan. When given a saved plan file (`-out=tfplan`), it applies exactly those changes — nothing more.

The workflow is always: **plan → review → apply**.

Reference: https://developer.hashicorp.com/terraform/cli/commands/plan

---

## 5. Remote State

By default Terraform stores state in a local `terraform.tfstate` file. This is unsuitable for teams because:
- The file cannot be shared safely.
- Concurrent applies corrupt the state.
- The file may contain sensitive values.

Remote state stores the file in a shared, durable backend (S3 in this project). All team members and CI/CD pipelines read and write the same state.

Reference: https://developer.hashicorp.com/terraform/language/settings/backends/s3

---

## 6. State Locking

When two `terraform apply` operations run simultaneously against the same state, they can corrupt it. State locking prevents this by acquiring an exclusive lock before any write operation.

If a lock is held, subsequent operations wait or fail with a clear error message.

Reference: https://developer.hashicorp.com/terraform/language/settings/backends/s3#dynamodb-state-locking

---

## 7. S3 State Storage

Amazon S3 provides durable, versioned, encrypted object storage. Terraform state stored in S3 benefits from:
- **Versioning** — previous state versions can be restored after a bad apply.
- **Encryption** — AES-256 server-side encryption protects sensitive values.
- **Access control** — IAM policies restrict who can read or write the state.
- **Durability** — 99.999999999% (11 nines) object durability.

Reference: https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html

---

## 8. DynamoDB Locking

DynamoDB provides a fast, consistent key-value store used by Terraform as a distributed lock. When Terraform begins an operation, it writes a record to the DynamoDB table with key `LockID`. When the operation completes, the record is deleted.

This project uses DynamoDB locking as explicitly required by the assignment. Modern Terraform (≥ 1.10) also supports native S3 lockfiles as an alternative, but DynamoDB locking is used here for assignment compliance and broad version compatibility.

Reference: https://developer.hashicorp.com/terraform/language/settings/backends/s3#dynamodb-state-locking

---

## 9. GitHub Actions Terraform Workflow

GitHub Actions automates the Terraform workflow on every pull request and push to main:

- **Pull request** → `fmt -check`, `init`, `validate`, `plan` — plan output is posted as a PR comment.
- **Push to main** → `init`, `plan`, `apply` — infrastructure is updated automatically.

AWS credentials are provided via **OIDC** (OpenID Connect), not long-lived access keys. GitHub Actions requests a short-lived token from AWS STS by presenting a signed JWT. No secrets are stored in GitHub.

Reference: https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services

---

## 10. Security Considerations

| Risk | Mitigation |
|------|-----------|
| Secrets in state | S3 encryption + restricted IAM access |
| Secrets in code | `sensitive = true` variables, `TF_VAR_` env vars |
| Long-lived AWS keys | OIDC — no static credentials |
| Public database | `publicly_accessible = false`, private subnets |
| Port 8080 exposed | App SG allows 8080 from ALB SG only |
| State corruption | DynamoDB locking |
| Accidental destroy | Manual `terraform apply` required locally; `environment: production` gate in GitHub Actions |

Reference: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
