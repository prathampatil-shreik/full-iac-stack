output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.app.arn
}

output "instance_ids" {
  description = "IDs of the EC2 application instances"
  value       = aws_instance.app[*].id
}

output "instance_private_ips" {
  description = "Private IP addresses of the EC2 application instances"
  value       = aws_instance.app[*].private_ip
}

output "compute_security_group_id" {
  description = "Security group ID of the application EC2 instances"
  value       = aws_security_group.app.id
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}
