locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  identifier = "${var.project_name}-${var.environment}-mysql"
}

# ------------------------------------------------------------------------------
# DB Subnet Group
# ------------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "DB subnet group for ${var.project_name}-${var.environment} RDS instance"
  subnet_ids  = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Log Groups for RDS
# ------------------------------------------------------------------------------

# Pre-create log groups so we control retention. If RDS auto-creates them,
# retention defaults to "Never expire" which wastes money.
resource "aws_cloudwatch_log_group" "rds_error" {
  name              = "/aws/rds/instance/${local.identifier}/error"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-error-logs"
  })
}

resource "aws_cloudwatch_log_group" "rds_slowquery" {
  name              = "/aws/rds/instance/${local.identifier}/slowquery"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-slowquery-logs"
  })
}

# ------------------------------------------------------------------------------
# RDS MySQL Instance
# ------------------------------------------------------------------------------

resource "aws_db_instance" "main" {
  identifier = local.identifier
  engine     = "mysql"

  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_name  = var.db_name
  username = var.master_username
  port     = var.port

  # Secrets Manager manages the master password (never stored in Terraform state)
  manage_master_user_password = true
  master_user_secret_kms_key_id = aws_kms_key.rds.arn

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  parameter_group_name   = aws_db_parameter_group.mysql.name

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:30-sun:05:30"

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  copy_tags_to_snapshot    = true
  deletion_protection      = var.deletion_protection
  skip_final_snapshot      = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.identifier}-final-snapshot"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-mysql"
  })

  depends_on = [
    aws_cloudwatch_log_group.rds_error,
    aws_cloudwatch_log_group.rds_slowquery,
  ]
}
