provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
      Purpose   = "terraform-remote-state"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  tags = merge(var.tags, {
    Project   = var.project_name
    ManagedBy = "Terraform"
    Purpose   = "terraform-remote-state"
  })
}

# --- S3 Bucket ----------------------------------------------------------------

resource "aws_s3_bucket" "state" {
  bucket        = var.state_bucket_name
  force_destroy = false

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

# --- Versioning ---------------------------------------------------------------
# Required for use_lockfile = true (Terraform >= 1.10 native S3 locking) and
# allows recovery of previous state versions if state becomes corrupted.

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# --- Server-Side Encryption ---------------------------------------------------
# SSE-S3 (AES256) encrypts all state files at rest.

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# --- Public Access Block ------------------------------------------------------
# All four settings are enabled. State files must never be publicly accessible.

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Ownership Controls -------------------------------------------------------
# BucketOwnerEnforced disables ACLs entirely. All access is controlled by
# bucket policies and IAM only.

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# --- Bucket Policy: Deny Insecure Transport -----------------------------------
# Denies all S3 requests that do not use TLS (HTTPS).
# This prevents state files from being read or written over unencrypted HTTP.

data "aws_iam_policy_document" "state_bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state_bucket_policy.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}
