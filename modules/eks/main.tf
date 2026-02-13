locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# ------------------------------------------------------------------------------
# CloudWatch Log Group for EKS Control Plane Logs
# ------------------------------------------------------------------------------

# Pre-create the log group so we control retention. If EKS auto-creates it,
# retention defaults to "Never expire" which wastes money.
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.control_plane_log_retention_days

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-logs"
  })
}

# ------------------------------------------------------------------------------
# Additional Cluster Security Group
# ------------------------------------------------------------------------------

# EKS auto-creates a "cluster security group" for control-plane <-> node comms.
# This additional SG lets you layer on custom rules later (e.g. bastion access).
resource "aws_security_group" "cluster_additional" {
  name        = "${var.project_name}-${var.environment}-eks-cluster-additional-sg"
  description = "Additional security group for EKS cluster ${var.cluster_name}"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster-additional-sg"
  })
}

resource "aws_vpc_security_group_egress_rule" "cluster_all_egress" {
  security_group_id = aws_security_group.cluster_additional.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ------------------------------------------------------------------------------
# EKS Cluster
# ------------------------------------------------------------------------------

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.endpoint_public_access_cidrs
    security_group_ids      = [aws_security_group.cluster_additional.id]
  }

  enabled_cluster_log_types = local.cluster_log_types

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster"
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.eks,
  ]
}

# ------------------------------------------------------------------------------
# Managed Node Group
# ------------------------------------------------------------------------------

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-node-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = var.node_instance_types
  disk_size       = var.node_disk_size

  scaling_config {
    min_size     = var.node_min_size
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-node-group"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_ecr_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ssm_policy,
  ]
}

# ------------------------------------------------------------------------------
# OIDC Provider for IRSA (IAM Roles for Service Accounts)
# ------------------------------------------------------------------------------

data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-oidc"
  })
}
