# ---------------------------------------------------------------------------
# Network layer
# ---------------------------------------------------------------------------
module "network" {
  source = "../modules/network"

  project_name             = var.project_name
  environment              = var.environment
  availability_zones       = var.availability_zones
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
}

# ---------------------------------------------------------------------------
# Compute layer — depends on network
# ---------------------------------------------------------------------------
module "compute" {
  source = "../modules/compute"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids
  private_app_subnet_ids = module.network.private_app_subnet_ids
  nat_gateway_id         = module.network.nat_gateway_id

  depends_on = [module.network]

  instance_count  = var.instance_count
  instance_type   = var.instance_type
  ecr_image_uri   = var.ecr_image_uri
  app_port        = var.app_port
  app_environment = var.app_environment
  app_version     = var.app_version
}

# ---------------------------------------------------------------------------
# Database layer — depends on network and compute (for the app SG)
# ---------------------------------------------------------------------------
module "database" {
  source = "../modules/database"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.network.vpc_id
  private_db_subnet_ids = module.network.private_db_subnet_ids
  app_security_group_id = module.compute.compute_security_group_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  db_instance_class     = var.db_instance_class
  db_allocated_storage  = var.db_allocated_storage
}

# ---------------------------------------------------------------------------
# CloudWatch — EC2 CPU alarms
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  count = var.instance_count

  alarm_name          = "${var.project_name}-${var.environment}-ec2-cpu-${count.index + 1}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "EC2 CPU utilization above 80%"

  dimensions = {
    InstanceId = module.compute.instance_ids[count.index]
  }

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# CloudWatch — ALB unhealthy host alarm
#
# AWS/ApplicationELB dimensions require the ARN *suffix* not the full ARN.
# ALB ARN format:  arn:aws:elasticloadbalancing:region:account:loadbalancer/app/name/id
# Required suffix: app/name/id
# TG ARN format:   arn:aws:elasticloadbalancing:region:account:targetgroup/name/id
# Required suffix: targetgroup/name/id
# ---------------------------------------------------------------------------
locals {
  alb_arn_suffix = join("/", slice(split("/", module.compute.alb_arn), 1, length(split("/", module.compute.alb_arn))))
  tg_arn_suffix  = join("/", slice(split("/", module.compute.target_group_arn), 1, length(split("/", module.compute.target_group_arn))))
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-${var.environment}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "One or more ALB targets are unhealthy"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
    TargetGroup  = local.tg_arn_suffix
  }

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# CloudWatch — RDS CPU alarm
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization above 80%"

  dimensions = {
    DBInstanceIdentifier = module.database.db_instance_identifier
  }

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# CloudWatch — RDS free storage alarm
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-free-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648 # 2 GB in bytes
  alarm_description   = "RDS free storage below 2 GB"

  dimensions = {
    DBInstanceIdentifier = module.database.db_instance_identifier
  }

  tags = {
    Environment = var.environment
  }
}

# ---------------------------------------------------------------------------
# CloudWatch Dashboard
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "full-iac-stack-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "EC2 CPU Utilization"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            for id in module.compute.instance_ids :
            ["AWS/EC2", "CPUUtilization", "InstanceId", id]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB Healthy / Unhealthy Hosts"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", local.alb_arn_suffix, "TargetGroup", local.tg_arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", local.alb_arn_suffix, "TargetGroup", local.tg_arn_suffix]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "RDS CPU Utilization"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", module.database.db_instance_identifier]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "RDS Free Storage Space"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", module.database.db_instance_identifier]
          ]
        }
      }
    ]
  })
}
