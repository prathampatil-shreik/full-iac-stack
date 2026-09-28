locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------------------------
# DB subnet group — uses private database subnets only
# ---------------------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  })
}

# ---------------------------------------------------------------------------
# Security group — RDS
# Port 3306 is only reachable from the application security group.
# 0.0.0.0/0 is never allowed to port 3306.
# ---------------------------------------------------------------------------
resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Allow MySQL/3306 only from application security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from application instances only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-sg"
  })
}

# ---------------------------------------------------------------------------
# RDS MySQL instance
#
# Cost-conscious settings for a personal test account:
#   - db.t3.micro
#   - 20 GB gp2 storage
#   - no Multi-AZ
#   - no deletion protection (allows clean teardown in test)
#   - skip_final_snapshot = true (no retained snapshot on destroy)
#
# For production: enable multi_az, deletion_protection, and final snapshots.
# ---------------------------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-${var.environment}-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  publicly_accessible = false
  multi_az            = false

  # Test account — allow clean destroy without a final snapshot
  deletion_protection      = false
  skip_final_snapshot      = true
  delete_automated_backups = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db"
  })
}
