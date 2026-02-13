variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource tagging"
  type        = string
  default     = "vibevault"
}

variable "vpc_id" {
  description = "ID of the VPC where the RDS instance will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnet IDs must be provided for the DB subnet group."
  }
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access the RDS instance on the MySQL port"
  type        = list(string)

  validation {
    condition     = length(var.allowed_security_group_ids) >= 1
    error_message = "At least 1 security group ID must be provided for RDS ingress."
  }
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.4"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage in GB for autoscaling"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type for the RDS instance"
  type        = string
  default     = "gp3"
}

variable "db_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "vibevault"
}

variable "master_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "admin"
}

variable "port" {
  description = "Port for the RDS instance"
  type        = number
  default     = 3306
}

variable "multi_az" {
  description = "Whether to deploy a Multi-AZ RDS instance"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when destroying the instance"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain RDS CloudWatch logs"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch Logs retention value."
  }
}
