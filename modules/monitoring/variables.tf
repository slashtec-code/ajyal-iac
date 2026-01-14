###############################################################################
# Monitoring Module Variables
###############################################################################

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_dashboards" {
  description = "Enable CloudWatch dashboards"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail"
  type        = bool
  default     = true
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "alarm_emails" {
  description = "List of emails for alarm notifications"
  type        = list(string)
  default     = []
}

variable "cpu_threshold" {
  description = "CPU alarm threshold percentage"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "Memory alarm threshold percentage"
  type        = number
  default     = 85
}

variable "disk_threshold" {
  description = "Disk alarm threshold percentage"
  type        = number
  default     = 80
}

variable "enable_siem_integration" {
  description = "Enable SIEM integration"
  type        = bool
  default     = false
}

variable "siem_sqs_queue_name" {
  description = "SQS queue name for SIEM integration"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Resource Identifiers for Per-Resource Alarms
#------------------------------------------------------------------------------

# ASG Names
variable "app_asg_name" {
  description = "App Auto Scaling Group name"
  type        = string
  default     = ""
}

variable "api_asg_name" {
  description = "API Auto Scaling Group name"
  type        = string
  default     = ""
}

# ALB ARN Suffixes (e.g., app/my-alb/50dc6c495c0c9188)
variable "app_alb_arn_suffix" {
  description = "App ALB ARN suffix for CloudWatch dimensions"
  type        = string
  default     = ""
}

variable "api_alb_arn_suffix" {
  description = "API ALB ARN suffix for CloudWatch dimensions"
  type        = string
  default     = ""
}

# Target Group ARN Suffixes
variable "app_target_group_arn_suffix" {
  description = "App Target Group ARN suffix"
  type        = string
  default     = ""
}

variable "api_target_group_arn_suffix" {
  description = "API Target Group ARN suffix"
  type        = string
  default     = ""
}

# Database Identifiers
variable "aurora_cluster_id" {
  description = "Aurora PostgreSQL cluster identifier"
  type        = string
  default     = ""
}

variable "mssql_instance_id" {
  description = "MSSQL RDS instance identifier"
  type        = string
  default     = ""
}

variable "opensearch_domain_name" {
  description = "OpenSearch domain name"
  type        = string
  default     = ""
}

# ElastiCache
variable "redis_cluster_id" {
  description = "Redis ElastiCache cluster ID"
  type        = string
  default     = ""
}

# EFS
variable "efs_file_system_id" {
  description = "EFS file system ID"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Threshold Variables
#------------------------------------------------------------------------------

variable "db_connections_threshold" {
  description = "Database connections alarm threshold"
  type        = number
  default     = 100
}

variable "aurora_max_capacity_threshold" {
  description = "Aurora Serverless max capacity threshold (ACUs)"
  type        = number
  default     = 4
}
