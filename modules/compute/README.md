# modules/compute

Provisions EC2 instances running the Dockerised application behind an Application Load Balancer.

## Resources

| Resource | Description |
|----------|-------------|
| `aws_iam_role` | EC2 instance role with ECR read access |
| `aws_iam_instance_profile` | Attaches the IAM role to EC2 |
| `aws_security_group` (alb) | Allows HTTP/80 from internet |
| `aws_security_group` (app) | Allows port 8080 from ALB SG only |
| `aws_lb` | Internet-facing Application Load Balancer |
| `aws_lb_target_group` | Target group with `/health` health check |
| `aws_lb_listener` | Port 80 → target group |
| `aws_instance` ×N | EC2 instances in private app subnets |
| `aws_lb_target_group_attachment` | Registers instances with target group |

## Security Design

```
Internet → port 80 → ALB SG → ALB
                               │
                               ▼ port 8080
                          App SG → EC2 instances
```

Port 8080 is **never** exposed directly to the internet. Only the ALB security group can reach it.

## User Data

`user_data.sh.tpl` runs on first boot:
1. Installs Docker via `dnf`
2. Authenticates to ECR using the instance IAM role
3. Pulls the application image
4. Runs the container with `--restart always`

## Usage

```hcl
module "compute" {
  source = "../modules/compute"

  project_name           = "full-iac-stack"
  environment            = "dev"
  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids
  private_app_subnet_ids = module.network.private_app_subnet_ids
  instance_count         = 2
  instance_type          = "t3.micro"
  ecr_image_uri          = "925213028316.dkr.ecr.ap-south-1.amazonaws.com/full-iac-stack-app:1.0.0"
  app_port               = 8080
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `alb_dns_name` | ALB DNS name — use this to reach the application |
| `alb_arn` | ALB ARN |
| `target_group_arn` | Target group ARN |
| `instance_ids` | EC2 instance IDs |
| `instance_private_ips` | EC2 private IPs |
| `compute_security_group_id` | App EC2 security group ID |
| `alb_security_group_id` | ALB security group ID |
