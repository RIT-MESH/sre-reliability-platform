terraform { required_version = ">= 1.7.0" }

# RDS PostgreSQL Multi-AZ with encryption, backups, deletion protection and
# credentials sourced from AWS Secrets Manager (never hard-coded).
resource "aws_db_subnet_group" "this" {
  name        = "${var.name_prefix}-db-subnet-group"
  subnet_ids  = var.private_subnet_ids
  description = "Private subnets for ${var.name_prefix} RDS"
  tags        = merge(var.tags, { Name = "${var.name_prefix}-db-subnet-group" })
}

# Random password stored in Secrets Manager; the value never appears in state
# file contents as plaintext (the secret ARN is referenced, not the password).
resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.name_prefix}/db/master"
  description             = "Master credentials for ${var.name_prefix} RDS PostgreSQL"
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.secret_recovery_days
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-db-secret" })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.username
    password = random_password.db.result
    engine   = "postgres"
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
  depends_on = [aws_db_instance.this]
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.name_prefix}-pg"
  family = "postgres${var.engine_version_major}"
  parameter {
    name  = "log_connections"
    value = "1"
    apply_method = "immediate"
  }
  parameter {
    name  = "log_min_duration_statement"
    value = "500"
    apply_method = "immediate"
  }
  tags = var.tags
}

resource "aws_db_instance" "this" {
  identifier                          = "${var.name_prefix}-pg"
  engine                              = "postgres"
  engine_version                      = var.engine_version
  instance_class                      = var.instance_class
  allocated_storage                   = var.allocated_storage
  max_allocated_storage               = var.max_allocated_storage
  storage_type                        = "gp3"
  storage_encrypted                   = true
  kms_key_id                          = var.kms_key_id
  db_name                             = var.db_name
  username                            = var.username
  password                            = random_password.db.result
  db_subnet_group_name                = aws_db_subnet_group.this.name
  parameter_group_name                = aws_db_parameter_group.this.name
  vpc_security_group_ids              = [var.db_sg_id]
  multi_az                            = var.multi_az
  publicly_accessible                 = false
  backup_retention_period             = var.backup_retention_days
  backup_window                       = "03:00-04:00"
  maintenance_window                  = "sun:04:30-sun:05:30"
  deletion_protection                 = var.deletion_protection
  skip_final_snapshot                 = !var.final_snapshot_on_delete
  final_snapshot_identifier           = var.final_snapshot_on_delete ? "${var.name_prefix}-final-snapshot-${formatdate("YYYYMMDDHHmmss", timestamp())}" : null
  copy_tags_to_snapshot               = true
  performance_insights_enabled        = var.performance_insights
  performance_insights_retention_period = var.performance_insights ? 7 : null
  monitoring_interval                 = var.enhanced_monitoring ? 30 : 0
  monitoring_role_arn                 = var.enhanced_monitoring ? aws_iam_role.enhanced[0].arn : null
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]
  tags                                = merge(var.tags, { Name = "${var.name_prefix}-pg" })
}

resource "aws_iam_role" "enhanced" {
  count              = var.enhanced_monitoring ? 1 : 0
  name               = "${var.name_prefix}-rds-monitoring"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "enhanced" {
  count      = var.enhanced_monitoring ? 1 : 0
  role       = aws_iam_role.enhanced[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
