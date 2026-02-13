data "aws_availability_zones" "available" {
  state = "available"
}

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
