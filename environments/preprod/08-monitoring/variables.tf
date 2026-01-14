###############################################################################
# Monitoring Module Variables
###############################################################################

variable "environment" {
  default = "preprod"
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "enable_cloudwatch_alarms" {
  default = true
}

variable "enable_cloudwatch_dashboards" {
  default = true
}

variable "enable_cloudtrail" {
  default = true
}

variable "log_retention_days" {
  default = 7 # Short retention for preprod to save cost
}

variable "alarm_emails" {
  description = "List of emails for alarm notifications"
  type        = list(string)
  default = [
    "muhamd.abdelhaliem@slashtec.com",
    "omar.mokheemer@slashtec.com",
    "dirar.harahsheh@slashtec.com"
  ]
}

variable "cpu_threshold" {
  default = 80
}

variable "memory_threshold" {
  default = 85
}

variable "disk_threshold" {
  default = 80
}

variable "enable_siem_integration" {
  default = false
}

variable "siem_sqs_queue_name" {
  default = ""
}

#------------------------------------------------------------------------------
# Threshold Variables
#------------------------------------------------------------------------------

variable "db_connections_threshold" {
  description = "Database connections alarm threshold"
  default     = 100
}

variable "aurora_max_capacity_threshold" {
  description = "Aurora Serverless max capacity threshold (ACUs)"
  default     = 4
}
