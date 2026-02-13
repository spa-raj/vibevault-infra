# ------------------------------------------------------------------------------
# Custom Parameter Group for MySQL 8.4
# ------------------------------------------------------------------------------

resource "aws_db_parameter_group" "mysql" {
  name        = "${var.project_name}-${var.environment}-mysql84"
  family      = "mysql8.4"
  description = "Custom parameter group for ${var.project_name}-${var.environment} MySQL 8.4"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "max_connections"
    value = "100"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "log_output"
    value = "FILE"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-mysql84"
  })
}
