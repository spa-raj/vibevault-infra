# Bootstrap — Terraform Remote State Backend

This directory provisions the S3 bucket and DynamoDB table used to store Terraform remote state for all environments.

## Why this exists

Terraform needs a backend to store state, but the backend resources themselves must be created first. This is the standard chicken-and-egg solution: bootstrap uses **local state** to create the remote state infrastructure that everything else depends on.

## Resources created

- **S3 bucket** (`vibevault-terraform-state`) — stores Terraform state files with versioning and encryption
- **DynamoDB table** (`vibevault-terraform-locks`) — provides state locking to prevent concurrent modifications

## Usage (one-time setup)

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

## Important

- Run this **once** before initializing any environment
- These resources are **not** managed by the main Terraform state
- **Never destroy** these resources — all environment state depends on them
- The local `.tfstate` in this directory is gitignored but should be backed up manually if needed
