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
