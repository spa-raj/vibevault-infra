output "domain_endpoint" {
  description = "HTTPS endpoint of the OpenSearch domain"
  value       = "https://${aws_opensearch_domain.main.endpoint}"
}

output "domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = aws_opensearch_domain.main.arn
}

output "domain_name" {
  description = "Name of the OpenSearch domain"
  value       = aws_opensearch_domain.main.domain_name
}

output "security_group_id" {
  description = "ID of the OpenSearch security group"
  value       = aws_security_group.opensearch.id
}
