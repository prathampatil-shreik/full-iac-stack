output "state_bucket_name" {
  description = "Name of the Terraform remote state S3 bucket"
  value       = aws_s3_bucket.state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the Terraform remote state S3 bucket"
  value       = aws_s3_bucket.state.arn
}

output "state_bucket_region" {
  description = "AWS region where the state bucket was created"
  value       = aws_s3_bucket.state.region
}

output "aws_account_id" {
  description = "AWS account ID — use this when constructing backend configurations"
  value       = data.aws_caller_identity.current.account_id
}
