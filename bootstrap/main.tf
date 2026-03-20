terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.31.0"
    }
  }
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = "vibevault-terraform-state"
  force_destroy = false

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name    = "vibevault-terraform-state"
    Project = "vibevault"
    Purpose = "Terraform remote state"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name                        = "vibevault-terraform-locks"
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "LockID"
  deletion_protection_enabled = true

  attribute {
    name = "LockID"
    type = "S"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name    = "vibevault-terraform-locks"
    Project = "vibevault"
    Purpose = "Terraform state locking"
  }
}

# ------------------------------------------------------------------------------
# GitHub OIDC Provider — lets GitHub Actions assume IAM roles without secrets
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]

  tags = {
    Name    = "github-oidc"
    Project = "vibevault"
  }
}

# ------------------------------------------------------------------------------
# IAM Role assumed by GitHub Actions via OIDC
# ------------------------------------------------------------------------------

variable "github_repos" {
  description = "GitHub repos allowed to assume the CI/CD role"
  type        = list(string)
  default = [
    "spa-raj/vibevault-infra",
    "spa-raj/userservice",
    "spa-raj/productservice",
    "spa-raj/cartservice",
    "spa-raj/orderservice",
    "spa-raj/paymentgateway",
    "spa-raj/notificationservice",
  ]
}

data "aws_iam_policy_document" "github_actions_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for repo in var.github_repos : "repo:${repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "vibevault-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json

  tags = {
    Name    = "vibevault-github-actions"
    Project = "vibevault"
    Purpose = "GitHub Actions CI/CD"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_role_arn" {
  description = "ARN to set as AWS_ROLE_ARN secret in all GitHub repos"
  value       = aws_iam_role.github_actions.arn
}
