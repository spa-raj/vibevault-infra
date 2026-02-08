# vibevault-infra

Terraform infrastructure for the VibeVault e-commerce platform on AWS.

## What This Repo Manages

| Module | AWS Resources |
|--------|--------------|
| VPC | VPC, public/private subnets, NAT Gateway, Internet Gateway, route tables |
| EKS | EKS cluster, managed node groups, IAM roles, OIDC provider (IRSA) |
| RDS | PostgreSQL RDS instance, parameter groups, subnet groups |
| ECR | Container registries for microservice Docker images |

## Architecture

All infrastructure is provisioned via Terraform and deployed to AWS. The EKS cluster hosts the VibeVault microservices:

- **User Service** — authentication and user management
- **Product Service** — product catalog and search
- **Cart Service** — shopping cart (Kafka-backed)
- **Order Service** — order processing (Saga pattern)
- **Payment Service** — payment processing
- **Notification Service** — email/SMS notifications

## Prerequisites

- [Terraform](https://www.terraform.io/) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- An AWS account

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Related Repositories

- [vibevault-roadmap](https://github.com/spa-raj/vibevault-roadmap) — Project roadmap and planning docs
