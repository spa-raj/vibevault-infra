# vibevault-infra

Terraform infrastructure and Kubernetes manifests for the VibeVault e-commerce platform on AWS.

## Terraform Modules

| Module | Resources | Instance |
|--------|-----------|----------|
| VPC | VPC (10.0.0.0/16), 2 public + 2 private subnets, NAT Gateway, Internet Gateway, route tables | ap-south-1, 2 AZs |
| EKS | EKS cluster (K8s 1.33), managed node group, OIDC provider (IRSA), EBS CSI driver, CloudWatch logging | 3x t3.medium |
| RDS | MySQL 8.4 instance, KMS encryption, automated backups (7 days), private subnet, security group | db.t3.micro, 20GB gp3 |
| ECR | 6 container image repositories, KMS encryption, scan-on-push, lifecycle policies | vibevault-dev/* |
| Secrets | Database credentials (4 services), RSA keypair (OAuth2), Razorpay credentials | KMS-encrypted |
| OpenSearch | OpenSearch 2.17 domain, VPC-internal, encryption at rest + in transit | t3.small.search |

### Bootstrap

S3 bucket for Terraform state, DynamoDB for state locking, GitHub OIDC provider for keyless CI/CD authentication across all 7 repositories.

### Staged Apply Order

```
Stage 1: VPC + ECR
Stage 2: EKS
Stage 3: RDS + Secrets Manager
Stage 4: OpenSearch + Full apply
```

## Kubernetes Manifests (`k8s/`)

| Resource | Description |
|----------|-------------|
| Kafka | Single-node KRaft (no Zookeeper), ClusterIP on port 9092, TCP socket probes |
| Kong Ingress Controller | Helm chart, NLB with TLS termination via ACM certificate, routes for 5 services |
| External Secrets Operator | ClusterSecretStore syncing AWS Secrets Manager → K8s Secrets via IRSA |
| DB Init Job | One-time Job creating per-service MySQL schemas and users |

### Kong Ingress Routes

| Path | Service |
|------|---------|
| `/auth`, `/oauth2`, `/login`, `/roles` | userservice |
| `/products`, `/categories`, `/search` | productservice |
| `/cart` | cartservice |
| `/orders` | orderservice |
| `/payments` | paymentgateway |

NotificationService is not exposed — it is a Kafka consumer only.

## Prerequisites

- [Terraform](https://www.terraform.io/) >= 1.9
- [AWS CLI](https://aws.amazon.com/cli/) v2, configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for K8s manifest management
- [Helm](https://helm.sh/) >= 3.0 for Kong deployment
- An AWS account with permissions for EKS, RDS, ECR, Secrets Manager, KMS, OpenSearch, SES, ACM

### Manual Setup

```bash
# 1. Bootstrap (one-time) — creates S3 state bucket + DynamoDB lock table
cd bootstrap && terraform init && terraform apply

# 2. Infrastructure (staged)
cd environments/dev
terraform init
terraform apply -target=module.vpc -target=module.ecr          # Stage 1
terraform apply -target=module.eks                              # Stage 2
terraform apply -target=module.rds -target=module.secrets       # Stage 3
terraform apply                                                 # Stage 4 (full)

# 3. Post-apply K8s setup
aws eks update-kubeconfig --name vibevault-dev --region ap-south-1
kubectl apply -f k8s/                                           # Kafka, ExternalSecrets, DB init
helm upgrade --install kong kong/kong -n kong --create-namespace -f k8s/kong-values.yaml
```

### Terraform State Backend

| Resource | Name | Region |
|---|---|---|
| S3 Bucket | `vibevault-terraform-state` | ap-south-1 |
| DynamoDB Table | `vibevault-terraform-locks` | ap-south-1 |
| State Key | `dev/terraform.tfstate` | — |

## CI/CD

GitHub Actions workflow (`infra.yaml`) supports:
- `terraform plan` / `terraform apply` / `terraform destroy` via workflow_dispatch
- Post-apply: deploys External Secrets Operator, DB init job, Kafka, and Kong
- AWS authentication via OIDC (no static credentials)

## Domain & HTTPS

- **Domain:** vibesvault.live (registered at name.com)
- **DNS:** CNAME `www.vibesvault.live` → NLB hostname
- **TLS:** ACM certificate, terminated at NLB (port 443 → HTTP to Kong)
- Route 53 is not used

## Related Repositories

| Repository | Description |
|---|---|
| [vibevault](https://github.com/spa-raj/vibevault) | Project overview with architecture diagrams |
| [userservice](https://github.com/spa-raj/userservice) | OAuth2 auth server, user management |
| [productservice](https://github.com/spa-raj/productservice) | Product catalogue, OpenSearch search |
| [cartservice](https://github.com/spa-raj/cartservice) | Shopping cart, MongoDB, Kafka producer |
| [orderservice](https://github.com/spa-raj/orderservice) | Order processing, saga pattern |
| [paymentgateway](https://github.com/spa-raj/paymentgateway) | Razorpay integration, webhooks |
| [notificationservice](https://github.com/spa-raj/notificationservice) | Email notifications via AWS SES |
