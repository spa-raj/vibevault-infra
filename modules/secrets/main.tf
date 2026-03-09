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
  override_special = "!#$%&*()-_=+[]{}:?"
}

resource "random_password" "productservice_db" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}:?"
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
# Userservice DB Credentials
# ------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "userservice_db" {
  name        = "${local.prefix}/userservice/db-credentials"
  description = "Database credentials for userservice"
  kms_key_id  = var.kms_key_arn

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
  name        = "${local.prefix}/productservice/db-credentials"
  description = "Database credentials for productservice"
  kms_key_id  = var.kms_key_arn

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
  name        = "${local.prefix}/userservice/app-secrets"
  description = "Application secrets for userservice (admin password, OAuth client secret)"
  kms_key_id  = var.kms_key_arn

  tags = merge(local.common_tags, {
    Service = "userservice"
  })
}

resource "aws_secretsmanager_secret_version" "userservice_app" {
  secret_id = aws_secretsmanager_secret.userservice_app.id
  secret_string = jsonencode({
    ADMIN_PASSWORD = random_password.userservice_admin.result
    CLIENT_SECRET  = random_password.userservice_client_secret.result
  })
}

