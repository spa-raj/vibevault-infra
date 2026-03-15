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
  description = "ID of the VPC where the OpenSearch domain will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for VPC endpoint placement"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 1
    error_message = "At least 1 private subnet ID must be provided."
  }
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access the OpenSearch domain (e.g. EKS worker nodes)"
  type        = list(string)

  validation {
    condition     = length(var.allowed_security_group_ids) >= 1
    error_message = "At least 1 security group ID must be provided for OpenSearch ingress."
  }
}

variable "engine_version" {
  description = "OpenSearch engine version"
  type        = string
  default     = "OpenSearch_2.17"
}

variable "instance_type" {
  description = "OpenSearch instance type"
  type        = string
  default     = "t3.small.search"
}

variable "instance_count" {
  description = "Number of data nodes in the cluster"
  type        = number
  default     = 1
}

variable "ebs_volume_size" {
  description = "Size of EBS volume per data node in GB"
  type        = number
  default     = 10
}

variable "ebs_volume_type" {
  description = "EBS volume type"
  type        = string
  default     = "gp3"
}

variable "multi_az" {
  description = "Whether to enable multi-AZ deployment (requires even instance_count)"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain OpenSearch CloudWatch logs"
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a valid CloudWatch Logs retention value."
  }
}
