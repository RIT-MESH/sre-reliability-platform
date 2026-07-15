terraform { required_version = ">= 1.7.0" }

# Least-privilege security groups. Each group references the others by ID so no
# broad 0.0.0.0/0 ingress is allowed on data tiers.

resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-sg-"
  vpc_id      = var.vpc_id
  description = "ALB security group"
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from internet (redirected to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-sg" })
}

resource "aws_security_group" "app" {
  name_prefix = "${var.name_prefix}-app-sg-"
  vpc_id      = var.vpc_id
  description = "Application EC2 security group"
  ingress {
    description     = "App port from ALB only"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    description = "Prometheus scrape (within VPC)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-app-sg" })
}

resource "aws_security_group" "db" {
  name_prefix = "${var.name_prefix}-db-sg-"
  vpc_id      = var.vpc_id
  description = "RDS security group"
  ingress {
    description     = "Postgres from app SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-db-sg" })
}

resource "aws_security_group" "redis" {
  name_prefix = "${var.name_prefix}-redis-sg-"
  vpc_id      = var.vpc_id
  description = "ElastiCache Redis security group"
  ingress {
    description     = "Redis from app SG"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-redis-sg" })
}
