output "vpc_id" {
  description = "ID of the existing default VPC"
  value       = data.aws_vpc.default.id
}

output "vpc_cidr" {
  description = "CIDR block of the existing default VPC"
  value       = data.aws_vpc.default.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the existing default public subnets (used for ALB and NAT Gateway)"
  value       = data.aws_subnet.default_public[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of the Terraform-managed private application subnets"
  value       = aws_subnet.private_app[*].id
}

output "private_db_subnet_ids" {
  description = "IDs of the Terraform-managed private database subnets"
  value       = aws_subnet.private_db[*].id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}
