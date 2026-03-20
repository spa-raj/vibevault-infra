locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  prefix = "${var.project_name}/${var.environment}"

}

# ------------------------------------------------------------------------------
# Random Passwords — auto-generated, never seen by humans
# ------------------------------------------------------------------------------

resource "random_password" "userservice_db" {
  length           = 32
  special          = true
  override_special = "!#%&*()-_=+:?"
}

resource "random_password" "productservice_db" {
  length           = 32
  special          = true
  override_special = "!#%&*()-_=+:?"
}

resource "random_password" "userservice_admin" {
  length  = 24
  special = true
}

resource "random_password" "userservice_client_secret" {
  length  = 48
  special = false
}

# ------------------------------------------------------------------------------
# RSA Key Pair for JWT Signing (persisted across pod restarts)
# ------------------------------------------------------------------------------

resource "tls_private_key" "jwt_signing" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# ------------------------------------------------------------------------------
# Userservice DB Credentials
# ------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "userservice_db" {
  name                    = "${local.prefix}/userservice/db-credentials"
  description             = "Database credentials for userservice"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0

  tags = merge(local.common_tags, {
    Service = "userservice"
  })
}

resource "aws_secretsmanager_secret_version" "userservice_db" {
  secret_id = aws_secretsmanager_secret.userservice_db.id
  secret_string = jsonencode({
    username = "userservice_user"
    password = random_password.userservice_db.result
  })
}

# ------------------------------------------------------------------------------
# Productservice DB Credentials
# ------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "productservice_db" {
  name                    = "${local.prefix}/productservice/db-credentials"
  description             = "Database credentials for productservice"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0

  tags = merge(local.common_tags, {
    Service = "productservice"
  })
}

resource "aws_secretsmanager_secret_version" "productservice_db" {
  secret_id = aws_secretsmanager_secret.productservice_db.id
  secret_string = jsonencode({
    username = "productservice_user"
    password = random_password.productservice_db.result
  })
}

# ------------------------------------------------------------------------------
# Userservice App Secrets (admin password, OAuth client secret)
# ------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "userservice_app" {
  name                    = "${local.prefix}/userservice/app-secrets"
  description             = "Application secrets for userservice (admin password, OAuth client secret)"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0

  tags = merge(local.common_tags, {
    Service = "userservice"
  })
}

resource "aws_secretsmanager_secret_version" "userservice_app" {
  secret_id = aws_secretsmanager_secret.userservice_app.id
  secret_string = jsonencode({
    ADMIN_PASSWORD  = random_password.userservice_admin.result
    CLIENT_SECRET   = random_password.userservice_client_secret.result
    RSA_PRIVATE_KEY = tls_private_key.jwt_signing.private_key_pem
    RSA_PUBLIC_KEY  = tls_private_key.jwt_signing.public_key_pem
  })
}

# ------------------------------------------------------------------------------
# Orderservice DB Credentials
# ------------------------------------------------------------------------------

resource "random_password" "orderservice_db" {
  length           = 32
  special          = true
  override_special = "!#%&*()-_=+:?"
}

resource "aws_secretsmanager_secret" "orderservice_db" {
  name                    = "${local.prefix}/orderservice/db-credentials"
  description             = "Database credentials for orderservice"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0

  tags = merge(local.common_tags, {
    Service = "orderservice"
  })
}

resource "aws_secretsmanager_secret_version" "orderservice_db" {
  secret_id = aws_secretsmanager_secret.orderservice_db.id
  secret_string = jsonencode({
    username = "orderservice_user"
    password = random_password.orderservice_db.result
  })
}

# ------------------------------------------------------------------------------
# Paymentgateway DB Credentials
# ------------------------------------------------------------------------------

resource "random_password" "paymentgateway_db" {
  length           = 32
  special          = true
  override_special = "!#%&*()-_=+:?"
}

resource "aws_secretsmanager_secret" "paymentgateway_db" {
  name                    = "${local.prefix}/paymentgateway/db-credentials"
  description             = "Database credentials for paymentgateway"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = 0

  tags = merge(local.common_tags, {
    Service = "paymentgateway"
  })
}

resource "aws_secretsmanager_secret_version" "paymentgateway_db" {
  secret_id = aws_secretsmanager_secret.paymentgateway_db.id
  secret_string = jsonencode({
    username = "paymentgateway_user"
    password = random_password.paymentgateway_db.result
  })
}

# ------------------------------------------------------------------------------
# Paymentgateway Razorpay Credentials
# Created manually via AWS CLI or deploy workflow (not managed by Terraform)
# aws secretsmanager create-secret --name "vibevault/dev/paymentgateway/razorpay-credentials" ...
# ------------------------------------------------------------------------------

