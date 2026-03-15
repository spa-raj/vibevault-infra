data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr           = "10.0.0.0/16"
  environment        = var.environment
  project_name       = "vibevault"
  cluster_name       = "vibevault-${var.environment}"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = "vibevault-${var.environment}"
  environment        = var.environment
  project_name       = "vibevault"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  kubernetes_version = "1.33"

  node_instance_types = ["t3.medium"]
  node_min_size       = 2
  node_desired_size   = 3
  node_max_size       = 5

  endpoint_public_access_cidrs     = ["0.0.0.0/0"]
  control_plane_log_retention_days = 7
  ci_cd_role_arn                   = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/vibevault-github-actions"
  create_ci_cd_access_entry        = false  # Access entry already exists outside Terraform

  secret_arns          = concat(module.secrets.all_secret_arns, [module.rds.master_user_secret_arn])
  secrets_kms_key_arns = [module.rds.kms_key_arn]
}

module "rds" {
  source = "../../modules/rds"

  environment        = var.environment
  project_name       = "vibevault"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  instance_class        = "db.t3.micro"
  engine_version        = "8.4"
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"

  db_name         = "vibevault"
  master_username = "admin"
  port            = 3306

  multi_az                = false
  backup_retention_period = 7
  deletion_protection     = false
  skip_final_snapshot     = true
  log_retention_days      = 7
}

module "secrets" {
  source = "../../modules/secrets"

  environment  = var.environment
  project_name = "vibevault"
  kms_key_arn  = module.rds.kms_key_arn
}

module "opensearch" {
  source = "../../modules/opensearch"

  environment        = var.environment
  project_name       = "vibevault"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  engine_version = "OpenSearch_2.17"
  instance_type  = "t3.small.search"
  instance_count = 1
  ebs_volume_size = 10
  ebs_volume_type = "gp3"

  multi_az           = false
  log_retention_days = 7
}

module "ecr" {
  source       = "../../modules/ecr"
  environment  = var.environment
  project_name = "vibevault"
}
