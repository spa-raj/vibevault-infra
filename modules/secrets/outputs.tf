output "userservice_db_secret_arn" {
  description = "ARN of the userservice DB credentials secret"
  value       = aws_secretsmanager_secret.userservice_db.arn
}

output "productservice_db_secret_arn" {
  description = "ARN of the productservice DB credentials secret"
  value       = aws_secretsmanager_secret.productservice_db.arn
}

output "userservice_app_secret_arn" {
  description = "ARN of the userservice app secrets"
  value       = aws_secretsmanager_secret.userservice_app.arn
}

output "all_secret_arns" {
  description = "List of all secret ARNs (for IAM policies)"
  value = [
    aws_secretsmanager_secret.userservice_db.arn,
    aws_secretsmanager_secret.productservice_db.arn,
    aws_secretsmanager_secret.userservice_app.arn,
    aws_secretsmanager_secret.orderservice_db.arn,
    aws_secretsmanager_secret.paymentgateway_db.arn,
  ]
}
