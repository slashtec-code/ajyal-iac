###############################################################################
# Patching Module Variables
###############################################################################

variable "environment" {
  default = "preprod"
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "enable_patching" {
  description = "Master toggle for patching"
  default     = true
}

variable "enable_windows_patching" {
  default = true
}

variable "windows_patch_schedule" {
  default = "cron(0 4 ? * SUN *)" # Sunday 4 AM UTC
}

variable "windows_patch_baseline" {
  default = "AWS-DefaultPatchBaseline"
}

variable "windows_maintenance_window_duration" {
  default = 4
}

variable "enable_linux_patching" {
  default = true
}

variable "linux_patch_schedule" {
  default = "cron(0 5 ? * SUN *)" # Sunday 5 AM UTC
}

variable "linux_patch_baseline" {
  default = "AWS-AmazonLinux2DefaultPatchBaseline"
}

variable "linux_maintenance_window_duration" {
  default = 4
}

variable "enable_patch_compliance" {
  default = true
}

variable "compliance_severity" {
  default = "CRITICAL"
}

variable "auto_approve_after_days" {
  default = 7
}

variable "enable_patch_notifications" {
  default = false # OFF for preprod
}

variable "notification_email" {
  default = ""
}
