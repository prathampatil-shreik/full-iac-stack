locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ---------------------------------------------------------------------------
# Data sources — existing default VPC and default public subnets
#
# Due to the AWS account VPC quota (max 5 VPCs), this project uses the
# existing default VPC instead of creating a new one. Terraform discovers
# the default VPC and its public subnets via data sources and does NOT
# create or modify them.
# ---------------------------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "defaultForAz"
    values = ["true"]
  }

  filter {
    name   = "availabilityZone"
    values = var.availability_zones
  }
}

# Resolve each default public subnet so we can reference the first one
# for the NAT Gateway placement.
data "aws_subnet" "default_public" {
  count             = length(var.availability_zones)
  vpc_id            = data.aws_vpc.default.id
  default_for_az    = true
  availability_zone = var.availability_zones[count.index]
}

# ---------------------------------------------------------------------------
# Private application subnets — Terraform-managed, inside default VPC
# CIDRs chosen to not overlap with existing default subnets:
#   172.31.0.0/20  (us-east-1b — existing)
#   172.31.16.0/20 (us-east-1c — existing)
#   172.31.32.0/20 (us-east-1a — existing)
# Safe range starts at 172.31.48.0 — using 172.31.100.x and 172.31.101.x
# ---------------------------------------------------------------------------
resource "aws_subnet" "private_app" {
  count = length(var.private_app_subnet_cidrs)

  vpc_id            = data.aws_vpc.default.id
  cidr_block        = var.private_app_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-app-${count.index + 1}"
    Tier = "private-app"
  })
}

# ---------------------------------------------------------------------------
# Private database subnets — Terraform-managed, inside default VPC
# Using 172.31.110.x and 172.31.111.x
# ---------------------------------------------------------------------------
resource "aws_subnet" "private_db" {
  count = length(var.private_db_subnet_cidrs)

  vpc_id            = data.aws_vpc.default.id
  cidr_block        = var.private_db_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-db-${count.index + 1}"
    Tier = "private-db"
  })
}

# ---------------------------------------------------------------------------
# Elastic IP for NAT Gateway
# ---------------------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  })
}

# ---------------------------------------------------------------------------
# NAT Gateway — placed in the default public subnet in us-east-1a
#
# NOTE: A single NAT Gateway is used to reduce cost in this test account.
# For production, deploy one NAT Gateway per AZ for high availability.
# The default VPC's IGW already exists — no new IGW is created.
# ---------------------------------------------------------------------------
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = data.aws_subnet.default_public[0].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat-gw"
  })
}

# ---------------------------------------------------------------------------
# Private application route table — outbound via NAT Gateway
# ---------------------------------------------------------------------------
resource "aws_route_table" "private_app" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-app-rt"
  })
}

resource "aws_route_table_association" "private_app" {
  count = length(aws_subnet.private_app)

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

# ---------------------------------------------------------------------------
# Private database route table — no internet route
# ---------------------------------------------------------------------------
resource "aws_route_table" "private_db" {
  vpc_id = data.aws_vpc.default.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-db-rt"
  })
}

resource "aws_route_table_association" "private_db" {
  count = length(aws_subnet.private_db)

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}
