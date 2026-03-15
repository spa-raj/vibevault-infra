output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
  sensitive   = true
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
  sensitive   = true
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
  sensitive   = true
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.vpc.nat_gateway_id
  sensitive   = true
}

# EKS Outputs

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
  sensitive   = true
}

output "eks_cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster API server"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
  sensitive   = true
}

# RDS Outputs

output "rds_endpoint" {
  description = "Connection endpoint of the RDS instance"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "rds_address" {
  description = "Hostname of the RDS instance"
  value       = module.rds.db_instance_address
  sensitive   = true
}

output "rds_port" {
  description = "Port of the RDS instance"
  value       = module.rds.db_instance_port
  sensitive   = true
}

output "rds_db_name" {
  description = "Name of the default database"
  value       = module.rds.db_name
  sensitive   = true
}

output "rds_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS master password"
  value       = module.rds.master_user_secret_arn
  sensitive   = true
}

# Secrets Manager Outputs

output "secrets_userservice_db_arn" {
  description = "ARN of the userservice DB credentials secret"
  value       = module.secrets.userservice_db_secret_arn
  sensitive   = true
}

output "secrets_productservice_db_arn" {
  description = "ARN of the productservice DB credentials secret"
  value       = module.secrets.productservice_db_secret_arn
  sensitive   = true
}

output "secrets_userservice_app_arn" {
  description = "ARN of the userservice app secrets"
  value       = module.secrets.userservice_app_secret_arn
  sensitive   = true
}

output "external_secrets_role_arn" {
  description = "ARN of the IRSA role for External Secrets Operator"
  value       = module.eks.external_secrets_role_arn
  sensitive   = true
}

# OpenSearch Outputs

output "opensearch_endpoint" {
  description = "HTTPS endpoint of the OpenSearch domain"
  value       = module.opensearch.domain_endpoint
  sensitive   = true
}

output "opensearch_domain_name" {
  description = "Name of the OpenSearch domain"
  value       = module.opensearch.domain_name
  sensitive   = true
}

output "opensearch_domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = module.opensearch.domain_arn
  sensitive   = true
}

# ECR Outputs

output "ecr_repository_urls" {
  description = "Map of service name to ECR repository URL"
  value       = module.ecr.repository_urls
  sensitive   = true
}
