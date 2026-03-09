terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    mysql = {
      source  = "petoju/mysql"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "vibevault-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "vibevault-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_secretsmanager_secret_version" "rds_master" {
  secret_id  = module.rds.master_user_secret_arn
  depends_on = [module.rds]
}

locals {
  rds_master_credentials = jsondecode(data.aws_secretsmanager_secret_version.rds_master.secret_string)
}

provider "mysql" {
  endpoint = module.rds.db_instance_endpoint
  username = local.rds_master_credentials["username"]
  password = local.rds_master_credentials["password"]
}
