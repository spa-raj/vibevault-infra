output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.vpc.nat_gateway_id
}

# EKS Outputs

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

# RDS Outputs

output "rds_endpoint" {
  description = "Connection endpoint of the RDS instance"
  value       = module.rds.db_instance_endpoint
}

output "rds_address" {
  description = "Hostname of the RDS instance"
  value       = module.rds.db_instance_address
}

output "rds_port" {
  description = "Port of the RDS instance"
  value       = module.rds.db_instance_port
}

output "rds_db_name" {
  description = "Name of the default database"
  value       = module.rds.db_name
}

output "rds_master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS master password"
  value       = module.rds.master_user_secret_arn
}
