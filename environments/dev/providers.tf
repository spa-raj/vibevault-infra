terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.31.0"
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
