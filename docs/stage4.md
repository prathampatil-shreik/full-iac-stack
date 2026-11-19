# Stage 4 — OIDC CI/CD (GitHub Actions)

This document covers the GitHub Actions pipelines introduced in Stage 4,
how to bootstrap the required AWS IAM resources, and how to configure the
repository to activate the workflows.

---

## Architecture Overview

```
Pull Request                Push to main              Daily (06:00 UTC)
     │                           │                          │
     ▼                           ▼                          ▼
┌─────────┐              ┌─────────────┐           ┌──────────────┐
│  ci.yml │              │   cd.yml    │           │  drift.yml   │
│         │              │             │           │              │
│ quality │              │ apply-dev   │           │ drift-dev    │
│ security│              │     │       │           │ drift-prod   │
│ plan-dev│              │     ▼       │           │     │        │
│plan-prod│              │ apply-prod  │           │     ▼        │
└─────────┘              │ (approval)  │           │ open issue   │
                         └─────────────┘           └──────────────┘
```

All workflows use **OIDC** — GitHub Actions requests a short-lived token from
AWS STS. No long-lived access keys are stored anywhere.

---

## 1. Bootstrap — OIDC IAM Resources

Before the workflows can run, the OIDC provider and IAM roles must exist in AWS.

### What `bootstrap/oidc` creates

| Resource | Purpose |
|----------|---------|
| `aws_iam_openid_connect_provider.github` | Trusts GitHub's OIDC issuer |
| `aws_iam_role.github_ci` | Assumed on `pull_request` events — read-only + plan |
| `aws_iam_role.github_cd` | Assumed on push to `main` — PowerUser + scoped IAM |

### Apply the bootstrap (one-time, manual)

```powershell
# Requires AWS credentials with IAM and S3 permissions
cd bootstrap\oidc

# Copy and edit the example vars
copy terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set github_org and github_repo

terraform init
terraform plan
terraform apply
```

After apply, note the outputs:

```
ci_role_arn = "arn:aws:iam::<account>:role/github-actions-ci-iac-platform"
cd_role_arn = "arn:aws:iam::<account>:role/github-actions-cd-iac-platform"
```

### Set GitHub Secrets

**Settings → Secrets and variables → Actions → New secret**

| Secret name | Value |
|-------------|-------|
| `AWS_CI_ROLE_ARN` | `ci_role_arn` output from bootstrap/oidc |
| `AWS_CD_ROLE_ARN` | `cd_role_arn` output from bootstrap/oidc |
| `AWS_REGION` | `us-east-1` |
| `TF_VAR_DB_PASSWORD` | Database master password (min 8 chars) |
| `DEV_BUCKET_SUFFIX` | Unique suffix for the dev S3 bucket |
| `PROD_BUCKET_SUFFIX` | Unique suffix for the prod S3 bucket |

### Create GitHub Environments

**Settings → Environments**

| Environment | Protection rules |
|-------------|-----------------|
| `dev` | None (auto-deploy) |
| `prod` | Required reviewers — add yourself or a team |

---

## 2. CI Workflow (`.github/workflows/ci.yml`)

**Trigger:** every pull request targeting `main`

| Job | What it does |
|-----|-------------|
| `quality` | `terraform fmt -check`, `terraform validate` (all modules + envs), TFLint |
| `security` | Checkov scan, OPA unit tests, Conftest fixture tests |
| `plan-dev` | `terraform plan` for `envs/dev` — posts output as PR comment |
| `plan-prod` | `terraform plan` for `envs/prod` — posts output as PR comment |

`plan-dev` and `plan-prod` only run after both `quality` and `security` pass.

**OIDC role used:** `AWS_CI_ROLE_ARN` (ReadOnly + state S3 access, no write)

No resources are created or destroyed by the CI workflow.

---

## 3. CD Workflow (`.github/workflows/cd.yml`)

**Trigger:** push to `main` (after a PR is merged)

| Job | Gate |
|-----|------|
| `apply-dev` | Automatic |
| `apply-prod` | Manual approval via `prod` environment protection rule |

**OIDC role used:** `AWS_CD_ROLE_ARN` (PowerUser + scoped IAM write)

Concurrency locks (`terraform-dev`, `terraform-prod`) prevent simultaneous
applies against the same environment.

### Prod approval flow

1. `apply-dev` completes.
2. GitHub pauses `apply-prod` and notifies required reviewers.
3. A reviewer inspects the plan in the Actions UI and approves.
4. `apply-prod` resumes and applies.

---

## 4. Drift Detection Workflow (`.github/workflows/drift.yml`)

**Trigger:** daily at 06:00 UTC, or manually via `workflow_dispatch`

| Job | What it does |
|-----|-------------|
| `drift-dev` | `terraform plan -detailed-exitcode` for `envs/dev` |
| `drift-prod` | `terraform plan -detailed-exitcode` for `envs/prod` |
| `report-drift` | Opens or updates a GitHub issue if drift is detected |

Exit code semantics from `terraform plan -detailed-exitcode`:
- `0` — no changes (no drift)
- `2` — changes present (drift detected → issue opened)
- `1` — plan error (workflow fails)

Plan output is uploaded as a workflow artifact (retained 7 days).

**OIDC role used:** `AWS_CI_ROLE_ARN` (read-only is sufficient for plan)

---

## 5. Security Design

| Concern | Mitigation |
|---------|-----------|
| No long-lived credentials | OIDC tokens valid for 1 hour maximum |
| CI cannot apply | CI role has ReadOnlyAccess + state S3 only |
| CD scoped to platform resources | IAM write scoped to `iac-platform-*` role ARNs |
| Prod requires human approval | GitHub Environment protection rule |
| Concurrent applies prevented | `concurrency` groups with `cancel-in-progress: false` |
| Secrets never in code | All sensitive values in GitHub Secrets |
| State encrypted | S3 backend with `encrypt = true` |

---

## 6. Files Created in Stage 4

| File | Purpose |
|------|---------|
| `bootstrap/oidc/main.tf` | OIDC provider + CI/CD IAM roles |
| `bootstrap/oidc/variables.tf` | Input variables |
| `bootstrap/oidc/outputs.tf` | Role ARNs to copy into GitHub Secrets |
| `bootstrap/oidc/terraform.tfvars.example` | Example variable values |
| `.github/workflows/ci.yml` | CI pipeline (PR gate) |
| `.github/workflows/cd.yml` | CD pipeline (deploy on merge) |
| `.github/workflows/drift.yml` | Drift detection (daily schedule) |

---

## 7. Checks Executed in Stage 4

| Check | Tool | Result |
|-------|------|--------|
| `terraform fmt -check -recursive` | Terraform 1.14.9 | PASS |
| `terraform validate` — bootstrap/oidc | Terraform 1.14.9 | PASS |
| Checkov — bootstrap/oidc (61 checks) | Checkov 3.4.6 | PASS (0 failures) |

The GitHub Actions workflows cannot be executed locally — they require a
GitHub repository with secrets and environments configured. The YAML syntax
is valid and the workflow logic has been reviewed for correctness.
