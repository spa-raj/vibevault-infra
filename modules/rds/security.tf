# ------------------------------------------------------------------------------
# Security Group for RDS MySQL Instance
# ------------------------------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for ${var.project_name}-${var.environment} RDS MySQL instance"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "rds_mysql" {
  count = length(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.rds.id
  description                  = "Allow MySQL access from allowed security group"
  from_port                    = var.port
  to_port                      = var.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
}
