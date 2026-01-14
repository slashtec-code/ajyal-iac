###############################################################################
# Database Module Variables
###############################################################################

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "db_security_group_id" {
  description = "Database security group ID"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
}

# MS SQL Server
variable "enable_mssql" {
  description = "Enable MS SQL Server RDS"
  type        = bool
  default     = true
}

variable "mssql_instance_class" {
  description = "MS SQL Server instance class"
  type        = string
  default     = "db.m6i.4xlarge"
}

variable "mssql_allocated_storage" {
  description = "MS SQL Server initial allocated storage in GB"
  type        = number
  default     = 100
}

variable "mssql_max_allocated_storage" {
  description = "MS SQL Server max storage for autoscaling in GB"
  type        = number
  default     = 200
}

variable "mssql_multi_az" {
  description = "Enable Multi-AZ for MS SQL Server"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Aurora PostgreSQL (Serverless v2)
# Storage auto-scales automatically (up to 128TB)
# Capacity uses ACUs (Aurora Capacity Units): 0.5 to 128
#------------------------------------------------------------------------------

variable "enable_postgresql" {
  description = "Enable Aurora PostgreSQL"
  type        = bool
  default     = true
}

variable "aurora_min_capacity" {
  description = "Aurora Serverless v2 minimum capacity (ACUs: 0.5-128)"
  type        = number
  default     = 0.5 # Minimum for cost savings in preprod
}

variable "aurora_max_capacity" {
  description = "Aurora Serverless v2 maximum capacity (ACUs: 0.5-128)"
  type        = number
  default     = 4 # Enough for preprod workloads
}

# OpenSearch
variable "enable_opensearch" {
  description = "Enable OpenSearch"
  type        = bool
  default     = true
}

variable "opensearch_instance_type" {
  description = "OpenSearch instance type"
  type        = string
  default     = "r5.2xlarge.search"
}

variable "opensearch_instance_count" {
  description = "Number of OpenSearch instances"
  type        = number
  default     = 3
}

variable "opensearch_volume_size" {
  description = "OpenSearch EBS volume size in GB"
  type        = number
  default     = 100
}

# Redis
variable "enable_redis" {
  description = "Enable ElastiCache Redis"
  type        = bool
  default     = true
}

variable "redis_node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.m5.2xlarge"
}

variable "redis_num_cache_nodes" {
  description = "Number of Redis cache nodes"
  type        = number
  default     = 3
}

# Common
variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}
