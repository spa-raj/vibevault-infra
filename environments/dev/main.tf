module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr           = "10.0.0.0/16"
  environment        = var.environment
  project_name       = "vibevault"
  cluster_name       = "vibevault-${var.environment}"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
}
