# Storage Module

Reusable Terraform module that provisions a secure, private Amazon S3 bucket with server-side encryption, versioning, public access blocking and bucket ownership controls enforced.

## Architecture

```
S3 Bucket (<project>-<env>-<suffix>)
├── Server-Side Encryption (AES256 / SSE-S3)
├── Versioning (Enabled)
├── Public Access Block (all four settings = true)
└── Ownership Controls (BucketOwnerEnforced — ACLs disabled)
```

## Features

- Globally unique bucket name via configurable suffix
- SSE-S3 (AES256) encryption enabled by default
- Bucket key enabled to reduce KMS request costs if upgraded to SSE-KMS
- Versioning enabled by default (configurable)
- All four public access block settings enforced
- Object ownership set to `BucketOwnerEnforced` — ACLs are disabled
- Consistent resource tagging

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_s3_bucket` | The S3 bucket |
| `aws_s3_bucket_versioning` | Versioning configuration |
| `aws_s3_bucket_server_side_encryption_configuration` | SSE-S3 encryption |
| `aws_s3_bucket_public_access_block` | Blocks all public access |
| `aws_s3_bucket_ownership_controls` | Enforces bucket owner, disables ACLs |

## Prerequisites

- Terraform >= 1.10.0
- AWS provider >= 6.0, < 7.0
- S3 bucket names are globally unique — choose a `bucket_suffix` that is unique to your account

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project_name` | Project name used in bucket naming | `string` | — | yes |
| `environment` | Deployment environment (`dev` or `prod`) | `string` | — | yes |
| `bucket_suffix` | Unique suffix for global bucket name uniqueness | `string` | — | yes |
| `versioning_enabled` | Enable bucket versioning | `bool` | `true` | no |
| `tags` | Map of tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | S3 bucket ID (same as bucket name) |
| `bucket_name` | S3 bucket name |
| `bucket_arn` | S3 bucket ARN |
| `bucket_region` | AWS region of the bucket |

## Example Usage

```hcl
module "storage" {
  source = "./modules/storage"

  project_name  = "iac-platform"
  environment   = "dev"
  bucket_suffix = "a1b2c3"

  tags = {
    Project   = "iac-platform"
    ManagedBy = "Terraform"
  }
}
```

The resulting bucket name will be: `iac-platform-dev-a1b2c3`

## Security Considerations

- All four `aws_s3_bucket_public_access_block` settings are `true` — no public access is possible
- `BucketOwnerEnforced` disables ACLs entirely; all access is controlled by bucket policies
- SSE-S3 encrypts all objects at rest automatically
- To upgrade to SSE-KMS, change `sse_algorithm` to `"aws:kms"` and supply a `kms_master_key_id`

## Cost Considerations

| Resource | Estimated Cost |
|----------|---------------|
| S3 storage | ~$0.023/GiB/month (Standard) |
| S3 requests | ~$0.0004 per 1,000 PUT/GET |
| Versioning | Older versions billed at standard storage rates |

S3 has no hourly instance charge. Costs are purely usage-based.

## Validation

```powershell
cd modules\storage\examples\basic
terraform init
terraform validate
terraform plan -var="bucket_suffix=a1b2c3"
```

## Cleanup

```powershell
terraform destroy -var="bucket_suffix=a1b2c3"
```

> Note: Versioned buckets must have all object versions deleted before the bucket can be destroyed. Terraform will fail on destroy if the bucket contains objects. Empty the bucket first or add a `force_destroy = true` argument to `aws_s3_bucket` for non-production use.
