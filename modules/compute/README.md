# Compute Module

Reusable Terraform module that provisions an Amazon ECS Fargate service behind an Application Load Balancer, with CloudWatch logging and a least-privilege IAM task execution role.

## Architecture

```
Internet
   |
Application Load Balancer (public subnets)
   |  ALB Security Group: allows :80 inbound
   |
ECS Fargate Tasks (private subnets)
   |  ECS Security Group: allows container port from ALB SG only
   |
CloudWatch Logs (/ecs/<project>-<env>)
```

> Private Fargate tasks require outbound internet access to pull container images
> from Docker Hub and to call AWS APIs (ECS, CloudWatch, ECR). Provide this via
> a NAT Gateway (recommended) or the required VPC interface endpoints.

## Features

- ECS Fargate cluster with Container Insights enabled
- Application Load Balancer in public subnets
- ECS tasks running in private subnets
- ALB security group restricted to HTTP inbound
- ECS security group restricted to ALB security group only
- Configurable container image, port, CPU, memory and desired count
- ALB target group with configurable health checks
- CloudWatch log group with configurable retention
- Least-privilege ECS task execution IAM role

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_ecs_cluster` | ECS cluster with Container Insights |
| `aws_ecs_task_definition` | Fargate task definition |
| `aws_ecs_service` | ECS service with ALB integration |
| `aws_lb` | Application Load Balancer |
| `aws_lb_target_group` | ALB target group (IP target type) |
| `aws_lb_listener` | HTTP listener on port 80 |
| `aws_security_group` (x2) | ALB and ECS security groups |
| `aws_security_group_rule` (x4) | Ingress and egress rules |
| `aws_iam_role` | ECS task execution role |
| `aws_iam_role_policy_attachment` | Attaches AmazonECSTaskExecutionRolePolicy |
| `aws_cloudwatch_log_group` | Container log group |

## Prerequisites

- Terraform >= 1.10.0
- AWS provider >= 6.0, < 7.0
- An existing VPC with public and private subnets (use the VPC module)
- Private subnets must have outbound internet access (NAT Gateway or VPC endpoints)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project_name` | Project name used in resource naming | `string` | — | yes |
| `environment` | Deployment environment (`dev` or `prod`) | `string` | — | yes |
| `vpc_id` | VPC ID where resources are deployed | `string` | — | yes |
| `public_subnet_ids` | Public subnet IDs for the ALB (min 2) | `list(string)` | — | yes |
| `private_subnet_ids` | Private subnet IDs for ECS tasks (min 2) | `list(string)` | — | yes |
| `container_image` | Docker image for the ECS container | `string` | `"nginx:alpine"` | no |
| `container_port` | Port the container listens on | `number` | `80` | no |
| `task_cpu` | ECS task CPU units | `number` | `256` | no |
| `task_memory` | ECS task memory in MiB | `number` | `512` | no |
| `desired_count` | Desired number of running tasks | `number` | `1` | no |
| `health_check_path` | ALB health check HTTP path | `string` | `"/"` | no |
| `log_retention_days` | CloudWatch log retention in days | `number` | `7` | no |
| `tags` | Map of tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `ecs_cluster_id` | ECS cluster ID |
| `ecs_cluster_name` | ECS cluster name |
| `ecs_service_name` | ECS service name |
| `ecs_service_id` | ECS service ID |
| `load_balancer_arn` | ALB ARN |
| `load_balancer_dns_name` | ALB DNS name (application URL) |
| `target_group_arn` | ALB target group ARN |
| `ecs_task_execution_role_arn` | ECS task execution role ARN |
| `alb_security_group_id` | ALB security group ID |
| `ecs_security_group_id` | ECS tasks security group ID |

## Example Usage

```hcl
module "compute" {
  source = "./modules/compute"

  project_name       = "iac-platform"
  environment        = "dev"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  container_image   = "nginx:alpine"
  container_port    = 80
  task_cpu          = 256
  task_memory       = 512
  desired_count     = 1

  tags = {
    Project   = "iac-platform"
    ManagedBy = "Terraform"
  }
}
```

## Security Considerations

- ECS tasks run in private subnets with no public IP
- ECS security group allows inbound only from the ALB security group
- IAM role uses only `AmazonECSTaskExecutionRolePolicy` — no wildcard permissions
- ALB listener is HTTP only; add HTTPS with ACM certificate for production

## Cost Considerations

| Resource | Estimated Cost |
|----------|---------------|
| ALB | ~$0.008/hr + $0.008/LCU-hr |
| Fargate task (256 CPU / 512 MB) | ~$0.01/hr per task |
| CloudWatch Logs | ~$0.50/GB ingested |

Set `desired_count = 0` to stop tasks without destroying infrastructure.

## Validation

```powershell
cd modules\compute\examples\basic
terraform init
terraform validate
# Supply real VPC/subnet IDs for plan
terraform plan -var="vpc_id=vpc-xxx" -var='public_subnet_ids=["subnet-a","subnet-b"]' -var='private_subnet_ids=["subnet-c","subnet-d"]'
```

## Cleanup

```powershell
terraform destroy
```
