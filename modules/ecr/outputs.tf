output "repository_urls" {
  description = "Map of repository name to ECR repository URL"
  value = {
    for name, repo in aws_ecr_repository.this : name => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of repository name to ECR repository ARN"
  value = {
    for name, repo in aws_ecr_repository.this : name => repo.arn
  }
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for ECR encryption"
  value       = aws_kms_key.ecr.arn
}
