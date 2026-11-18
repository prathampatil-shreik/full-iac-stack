locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ── DB Subnet Group ───────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "this" {
  name        = "${local.name_prefix}-db-subnet-group"
  description = "Subnet group for ${local.name_prefix} RDS instance"
  subnet_ids  = var.private_subnet_ids

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-db-subnet-group"
    Environment = var.environment
  })
}

# ── Database Security Group ───────────────────────────────────────────────────

resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db-sg"
  description = "Allow database access from the application security group only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-db-sg"
    Environment = var.environment
  })
}

resource "aws_security_group_rule" "db_ingress" {
  security_group_id        = aws_security_group.db.id
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_id
  description              = "Allow MySQL from application security group"
}

resource "aws_security_group_rule" "db_egress" {
  security_group_id = aws_security_group.db.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound"
}

# ── RDS MySQL Instance ────────────────────────────────────────────────────────
#
# Engine version: mysql 8.0
# To verify supported versions in us-east-1, run:
#   aws rds describe-db-engine-versions --engine mysql --region us-east-1 \
#     --query "DBEngineVersions[].EngineVersion"

resource "aws_db_instance" "this" {
  identifier = "${local.name_prefix}-db"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.instance_class

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = var.db_port

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  multi_az            = var.multi_az
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name_prefix}-db-final-snapshot"

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-db"
    Environment = var.environment
  })
}
