###############################################################################
# Patching Module Variables
###############################################################################

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_patching" {
  description = "Master toggle - Enable SSM Patch Manager"
  type        = bool
  default     = true
}

variable "enable_windows_patching" {
  description = "Enable Windows Server patching"
  type        = bool
  default     = true
}

variable "windows_patch_schedule" {
  description = "Cron expression for Windows patching schedule"
  type        = string
  default     = "cron(0 4 ? * SUN *)"
}

variable "windows_patch_baseline" {
  description = "Windows patch baseline"
  type        = string
  default     = "AWS-DefaultPatchBaseline"
}

variable "windows_maintenance_window_duration" {
  description = "Windows maintenance window duration in hours"
  type        = number
  default     = 4
}

variable "enable_linux_patching" {
  description = "Enable Linux server patching"
  type        = bool
  default     = true
}

variable "linux_patch_schedule" {
  description = "Cron expression for Linux patching schedule"
  type        = string
  default     = "cron(0 5 ? * SUN *)"
}

variable "linux_patch_baseline" {
  description = "Linux patch baseline"
  type        = string
  default     = "AWS-AmazonLinux2DefaultPatchBaseline"
}

variable "linux_maintenance_window_duration" {
  description = "Linux maintenance window duration in hours"
  type        = number
  default     = 4
}

variable "enable_patch_compliance" {
  description = "Enable patch compliance reporting"
  type        = bool
  default     = true
}

variable "compliance_severity" {
  description = "Minimum severity level for compliance"
  type        = string
  default     = "CRITICAL"
}

variable "auto_approve_after_days" {
  description = "Days after which patches are auto-approved"
  type        = number
  default     = 7
}

variable "enable_patch_notifications" {
  description = "Enable SNS notifications for patching events"
  type        = bool
  default     = true
}

variable "notification_email" {
  description = "Email address for patch notifications"
  type        = string
  default     = ""
}
