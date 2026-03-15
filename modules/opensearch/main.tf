locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  domain_name = "${var.project_name}-${var.environment}"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# CloudWatch Log Group for OpenSearch
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "opensearch" {
  name              = "/aws/opensearch/${local.domain_name}/index-slow-logs"
  retention_in_days = var.log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-opensearch-logs"
  })
}

resource "aws_cloudwatch_log_resource_policy" "opensearch" {
  policy_name = "${local.domain_name}-opensearch-log-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "es.amazonaws.com"
        }
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
        ]
        Resource = "${aws_cloudwatch_log_group.opensearch.arn}:*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# OpenSearch Domain
# ------------------------------------------------------------------------------

resource "aws_opensearch_domain" "main" {
  domain_name    = local.domain_name
  engine_version = var.engine_version

  lifecycle {
    precondition {
      condition     = !var.multi_az || length(var.private_subnet_ids) >= 2
      error_message = "At least 2 private subnet IDs are required when multi_az is enabled."
    }
    precondition {
      condition     = !var.multi_az || (var.instance_count >= 2 && var.instance_count % 2 == 0)
      error_message = "instance_count must be at least 2 and even when multi_az is enabled."
    }
  }

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    zone_awareness_enabled = var.multi_az

    dynamic "zone_awareness_config" {
      for_each = var.multi_az ? [1] : []
      content {
        availability_zone_count = 2
      }
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.ebs_volume_size
    volume_type = var.ebs_volume_type
  }

  vpc_options {
    subnet_ids         = var.multi_az ? slice(var.private_subnet_ids, 0, 2) : [var.private_subnet_ids[0]]
    security_group_ids = [aws_security_group.opensearch.id]
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  # Restrict to HTTP actions only — network access is controlled via VPC security group
  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "es:ESHttp*"
        Resource  = "arn:aws:es:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:domain/${local.domain_name}/*"
      }
    ]
  })

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch.arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-opensearch"
  })

  depends_on = [
    aws_cloudwatch_log_resource_policy.opensearch,
  ]
}
