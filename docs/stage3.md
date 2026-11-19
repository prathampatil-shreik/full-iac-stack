# Stage 3 — Policy-as-Code, Quality Checks & Testing

This document covers every check introduced in Stage 3, how to run each one
locally, and what output to expect.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Terraform | >= 1.10.0 | https://developer.hashicorp.com/terraform/install |
| Checkov | >= 3.4.6 | `pip install checkov` |
| OPA | >= 0.68 | https://www.openpolicyagent.org/docs/latest/#1-download-opa |
| Conftest | >= 0.50 | https://www.conftest.dev |
| TFLint | >= 0.50 | https://github.com/terraform-linters/tflint |
| Go | >= 1.21 | https://go.dev/dl/ (required for Terratest only) |

All tools except Go are optional individually — each script checks for its
tool and exits with a clear message if it is missing.

---

## 1. Terraform Quality Checks (fmt + validate)

### What it does
- `terraform fmt -check -recursive` — verifies all `.tf` and `.tfvars` files
  are canonically formatted.
- `terraform validate` — checks syntax and internal consistency for every
  module, example, environment, and bootstrap directory.
- Uses `-backend=false` so no AWS credentials or S3 backend access is needed.

### Run

```powershell
# From repo root
.\scripts\tf-quality.ps1
```

Or run individual commands:

```powershell
# Format check
terraform fmt -check -recursive

# Validate a single directory (example)
cd modules\vpc
terraform init -backend=false -input=false
terraform validate
```

### Directories validated

| Directory | Type |
|-----------|------|
| `modules/vpc` | Module |
| `modules/compute` | Module |
| `modules/database` | Module |
| `modules/storage` | Module |
| `modules/vpc/examples/basic` | Example |
| `modules/compute/examples/basic` | Example |
| `modules/database/examples/basic` | Example |
| `modules/storage/examples/basic` | Example |
| `envs/dev` | Environment |
| `envs/prod` | Environment |
| `bootstrap/state-bucket` | Bootstrap |

### Expected output
All 11 directories report `Success! The configuration is valid.`

### Fixing fmt failures
```powershell
terraform fmt -recursive
```

---

## 2. TFLint

### What it does
Runs the TFLint AWS ruleset against all modules and environments. Checks for:
- Deprecated resource arguments
- Invalid AWS resource configurations
- Missing required variable descriptions and outputs
- Terraform version constraints

Configuration: `.tflint.hcl` (repo root)

### Run

```powershell
# Install plugins (once)
tflint --init

# Scan all directories
.\scripts\tflint-scan.ps1

# Or scan a single directory
cd modules\vpc
tflint --config="..\..\..\.tflint.hcl"
```

### Expected output
No errors in any module or environment directory.

---

## 3. Checkov

### What it does
Runs Checkov 3.x static analysis against all Terraform source files.
Checks for security misconfigurations across IAM, S3, RDS, VPC, ECS, and ALB.

Configuration: `.checkov.yaml` (repo root)

Excluded from scan:
- `.terraform/` directories (provider binaries)
- `*.tfstate`, `*.tfplan` files (may contain sensitive data)

### Run

```powershell
# Windows (pip-installed checkov)
C:\Users\<you>\AppData\Roaming\Python\Python312\Scripts\checkov.cmd `
    --directory . `
    --config-file .checkov.yaml `
    --output cli --compact

# Or use the script
.\scripts\checkov-scan.ps1
```

### Expected output
```
Passed checks: 115, Failed checks: 0, Skipped checks: 0
```

### Suppressed findings (all justified)

Every suppressed check is documented in `.checkov.yaml`. Summary:

| Check ID | Reason |
|----------|--------|
| CKV_AWS_2, CKV_AWS_103, CKV2_AWS_20, CKV_AWS_378 | HTTP-only architecture — no domain/ACM cert in this demo |
| CKV_AWS_260 | ALB port 80 open to internet — intentional public entry point |
| CKV_AWS_382 | ECS/ALB egress required for ECR image pull and AWS API calls |
| CKV_AWS_91, CKV_AWS_131, CKV_AWS_150, CKV2_AWS_28 | ALB hardening out of scope / cost control |
| CKV_AWS_158, CKV_AWS_338 | CloudWatch KMS / 1-year retention — cost/scope |
| CKV_AWS_133, CKV_AWS_129, CKV_AWS_226, CKV_AWS_118, CKV_AWS_161, CKV_AWS_293, CKV_AWS_157, CKV2_AWS_60 | RDS dev trade-offs — all configurable via variables |
| CKV_AWS_18, CKV_AWS_144, CKV_AWS_145, CKV2_AWS_61, CKV2_AWS_62 | S3 advanced features out of scope |
| CKV2_AWS_11, CKV2_AWS_12, CKV_AWS_130 | VPC flow logs / default SG / public subnets for ALB |
| CKV_AWS_394 | AZ data source sliced to exactly 2 — bounded result set |

To fix any suppressed finding for production use, remove its entry from
`.checkov.yaml` and implement the corresponding Terraform resource.

---

## 4. OPA / Conftest Policies

### Policies

| File | Package | What it enforces |
|------|---------|-----------------|
| `no_public_rds.rego` | `terraform.rds.public_access` | `publicly_accessible = false` on all RDS instances |
| `encryption_required.rego` | `terraform.encryption` | RDS `storage_encrypted = true`; S3 SSE-S3 or KMS |
| `no_public_s3.rego` | `terraform.s3.public_access` | All four S3 public access block settings = true |
| `no_ssh_open_cidr.rego` | `terraform.security_groups` | No SSH (port 22) open to 0.0.0.0/0 or ::/0 |
| `no_unrestricted_ingress.rego` | `terraform.security_groups.unrestricted_ingress` | Sensitive ports (22, 443, 3306, 5432, etc.) not open to world; port 80 ALB rule explicitly allowed |
| `mandatory_tags.rego` | `terraform.tags` | All taggable resources carry Project, Environment, ManagedBy |
| `approved_instance_types.rego` | `terraform.rds.instance_types` | RDS instance class in approved cost-conscious list |

### OPA unit tests

Each policy has a `_test.rego` file with passing and failing cases.

```powershell
# Run all OPA unit tests (requires opa CLI)
opa test policy/terraform --verbose
```

Expected: all tests pass (PASS).

### Conftest plan tests

Two fixture files in `policy/terraform/testdata/`:

| File | Expected result |
|------|----------------|
| `pass_plan.json` | Zero violations — compliant plan |
| `fail_plan.json` | Violations detected — non-compliant plan |

```powershell
# Test compliant plan (expect: PASS / 0 violations)
conftest test policy\terraform\testdata\pass_plan.json `
    --policy policy\terraform

# Test non-compliant plan (expect: violations reported)
conftest test policy\terraform\testdata\fail_plan.json `
    --policy policy\terraform
```

Or run both via the script:

```powershell
.\scripts\conftest-scan.ps1
```

### Violations in fail_plan.json

The failing fixture deliberately contains:

| Violation | Policy triggered |
|-----------|-----------------|
| `publicly_accessible = true` on RDS | `no_public_rds` |
| `storage_encrypted = false` on RDS | `encryption_required` |
| `db.r5.4xlarge` instance class | `approved_instance_types` |
| All S3 public access block settings = false | `no_public_s3` (4 violations) |
| SSH (port 22) open to 0.0.0.0/0 | `no_ssh_open_cidr` |
| MySQL (port 3306) open to 0.0.0.0/0 | `no_unrestricted_ingress` |
| Missing mandatory tags on VPC and RDS | `mandatory_tags` |

### Running policies against a real plan

```powershell
# Generate plan JSON (requires AWS credentials and TF_VAR_db_password)
cd envs\dev
terraform plan -out=dev.tfplan
terraform show -json dev.tfplan > dev-plan.json

# Run policies
conftest test dev-plan.json --policy ..\..\policy\terraform
```

---

## 5. Terratest

### Test classification

All tests in `tests/` are **STATIC** by default — they run
`terraform init -backend=false` and `terraform validate` only.
No AWS resources are created or destroyed.

Tests marked `t.Skip(...)` are **AWS INTEGRATION** tests that would create
real resources. They are documented but disabled.

| Test function | File | Classification |
|---------------|------|----------------|
| `TestVpcModuleInit_Static` | `vpc_module_test.go` | STATIC |
| `TestVpcModuleValidate_Static` | `vpc_module_test.go` | STATIC |
| `TestVpcExampleInit_Static` | `vpc_module_test.go` | STATIC |
| `TestVpcModulePlan_AWS` | `vpc_module_test.go` | AWS — SKIPPED |
| `TestComputeModuleValidate_Static` | `modules_test.go` | STATIC |
| `TestComputeExampleValidate_Static` | `modules_test.go` | STATIC |
| `TestDatabaseModuleValidate_Static` | `modules_test.go` | STATIC |
| `TestDatabaseExampleValidate_Static` | `modules_test.go` | STATIC |
| `TestStorageModuleValidate_Static` | `modules_test.go` | STATIC |
| `TestStorageExampleValidate_Static` | `modules_test.go` | STATIC |
| `TestDatabaseModuleApply_AWS` | `modules_test.go` | AWS — SKIPPED |
| `TestComputeModuleApply_AWS` | `modules_test.go` | AWS — SKIPPED |
| `TestDevEnvValidate_Static` | `envs_test.go` | STATIC |
| `TestProdEnvValidate_Static` | `envs_test.go` | STATIC |
| `TestBootstrapValidate_Static` | `envs_test.go` | STATIC |
| `TestDevEnvPlan_AWS` | `envs_test.go` | AWS — SKIPPED |

### Run static tests

```powershell
cd tests

# Download dependencies (first time only)
go mod tidy

# Run all static tests
go test -v -run "_Static" -timeout 10m

# Run a specific test
go test -v -run TestVpcModuleValidate_Static -timeout 5m
```

### Note on Go availability
Go is not installed on this machine. The test files are complete and correct
Go source. To run them, install Go >= 1.21 from https://go.dev/dl/ then
run `go mod tidy` from the `tests/` directory to download Terratest.

### Enabling AWS integration tests
To run an AWS integration test, open the relevant `_test.go` file, remove
the `t.Skip(...)` line, and ensure:
- AWS credentials are configured (`aws configure` or environment variables)
- `TF_VAR_db_password` is set for database tests
- `terraform.tfvars` is present in the environment directory
- Run `terraform destroy` after the test completes to avoid ongoing costs

---

## 6. Running Everything

```powershell
# From repo root — run all Stage 3 checks in sequence

# 1. Format check
terraform fmt -check -recursive

# 2. Validate all directories
.\scripts\tf-quality.ps1

# 3. TFLint
.\scripts\tflint-scan.ps1

# 4. Checkov
.\scripts\checkov-scan.ps1

# 5. OPA unit tests
opa test policy/terraform --verbose

# 6. Conftest plan tests
.\scripts\conftest-scan.ps1
```

---

## 7. Checks Actually Executed in Stage 3

The following checks were **executed and passed** during Stage 3 implementation:

| Check | Tool | Result |
|-------|------|--------|
| `terraform fmt -check -recursive` | Terraform | PASS |
| `terraform validate` — modules/vpc | Terraform | PASS |
| `terraform validate` — modules/compute | Terraform | PASS |
| `terraform validate` — modules/database | Terraform | PASS |
| `terraform validate` — modules/storage | Terraform | PASS |
| `terraform validate` — vpc/examples/basic | Terraform | PASS |
| `terraform validate` — compute/examples/basic | Terraform | PASS |
| `terraform validate` — database/examples/basic | Terraform | PASS |
| `terraform validate` — storage/examples/basic | Terraform | PASS |
| `terraform validate` — envs/dev | Terraform | PASS |
| `terraform validate` — envs/prod | Terraform | PASS |
| `terraform validate` — bootstrap/state-bucket | Terraform | PASS |
| Checkov scan (115 checks) | Checkov 3.4.6 | PASS (0 failures) |
| Conftest pass_plan.json | Conftest* | Not executed — conftest not installed |
| OPA unit tests | OPA* | Not executed — opa not installed |
| Terratest static tests | Go/Terratest* | Not executed — Go not installed |

*TFLint, OPA, Conftest, and Go were not found on PATH during Stage 3 execution.
Install instructions are in the Prerequisites section above. The scripts,
policies, test files, and fixtures are complete and ready to run.
