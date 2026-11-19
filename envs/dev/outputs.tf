# ── VPC ───────────────────────────────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs (empty when NAT is disabled)"
  value       = module.vpc.nat_gateway_ids
}

# ── Compute ───────────────────────────────────────────────────────────────────

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.compute.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.compute.ecs_service_name
}

output "load_balancer_dns_name" {
  description = "ALB DNS name — application is accessible at http://<this value>"
  value       = module.compute.load_balancer_dns_name
}

output "ecs_security_group_id" {
  description = "ECS tasks security group ID"
  value       = module.compute.ecs_security_group_id
}

# ── Database ──────────────────────────────────────────────────────────────────

output "db_instance_identifier" {
  description = "RDS instance identifier"
  value       = module.database.db_instance_identifier
}

output "db_endpoint" {
  description = "RDS connection endpoint"
  value       = module.database.db_endpoint
}

output "db_name" {
  description = "Database name"
  value       = module.database.db_name
}

# ── Storage ───────────────────────────────────────────────────────────────────

output "bucket_name" {
  description = "S3 bucket name"
  value       = module.storage.bucket_name
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.storage.bucket_arn
}
