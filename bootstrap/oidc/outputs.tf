output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "ci_role_arn" {
  description = "ARN of the CI IAM role (plan-only, assumed on pull_request events). Set as GitHub secret: AWS_CI_ROLE_ARN"
  value       = aws_iam_role.github_ci.arn
}

output "cd_role_arn" {
  description = "ARN of the CD IAM role (apply, assumed on push to main). Set as GitHub secret: AWS_CD_ROLE_ARN"
  value       = aws_iam_role.github_cd.arn
}

output "aws_account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}
