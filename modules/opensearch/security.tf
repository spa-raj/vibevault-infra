# ------------------------------------------------------------------------------
# Security Group for OpenSearch Domain
# ------------------------------------------------------------------------------

resource "aws_security_group" "opensearch" {
  name        = "${var.project_name}-${var.environment}-opensearch-sg"
  description = "Security group for ${var.project_name}-${var.environment} OpenSearch domain"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-opensearch-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "opensearch_https" {
  count = length(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.opensearch.id
  description                  = "Allow HTTPS access from allowed security group"
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
}
