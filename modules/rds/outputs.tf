output "db_instance_endpoint" {
  description = "Connection endpoint of the RDS instance (includes port)"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  description = "Hostname of the RDS instance (without port)"
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.main.port
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_instance_identifier" {
  description = "Identifier of the RDS instance"
  value       = aws_db_instance.main.identifier
}

output "db_name" {
  description = "Name of the default database"
  value       = aws_db_instance.main.db_name
}

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the master password"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for RDS encryption"
  value       = aws_kms_key.rds.arn
}
