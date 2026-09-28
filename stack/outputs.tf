# ---------------------------------------------------------------------------
# Network outputs
# ---------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs"
  value       = module.network.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs"
  value       = module.network.private_db_subnet_ids
}

# ---------------------------------------------------------------------------
# Compute outputs
# ---------------------------------------------------------------------------
output "alb_dns_name" {
  description = "ALB DNS name — use this URL to reach the application"
  value       = module.compute.alb_dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = module.compute.alb_arn
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = module.compute.target_group_arn
}

output "instance_ids" {
  description = "EC2 instance IDs"
  value       = module.compute.instance_ids
}

output "instance_private_ips" {
  description = "EC2 private IP addresses"
  value       = module.compute.instance_private_ips
}

output "compute_security_group_id" {
  description = "Application EC2 security group ID"
  value       = module.compute.compute_security_group_id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.compute.alb_security_group_id
}

# ---------------------------------------------------------------------------
# Database outputs — password is intentionally excluded
# ---------------------------------------------------------------------------
output "db_endpoint" {
  description = "RDS endpoint (host:port)"
  value       = module.database.db_endpoint
}

output "db_port" {
  description = "RDS port"
  value       = module.database.db_port
}

output "db_instance_identifier" {
  description = "RDS instance identifier"
  value       = module.database.db_instance_identifier
}

output "db_security_group_id" {
  description = "Database security group ID"
  value       = module.database.db_security_group_id
}

# ---------------------------------------------------------------------------
# Application URL
# ---------------------------------------------------------------------------
output "application_url" {
  description = "Application URL via ALB"
  value       = "http://${module.compute.alb_dns_name}"
}

output "health_check_url" {
  description = "ALB health check URL"
  value       = "http://${module.compute.alb_dns_name}/health"
}
