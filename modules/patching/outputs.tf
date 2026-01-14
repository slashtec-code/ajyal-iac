###############################################################################
# Patching Module Outputs
###############################################################################

output "windows_patch_baseline_id" {
  description = "Windows patch baseline ID"
  value       = var.enable_patching && var.enable_windows_patching ? aws_ssm_patch_baseline.windows[0].id : null
}

output "linux_patch_baseline_id" {
  description = "Linux patch baseline ID"
  value       = var.enable_patching && var.enable_linux_patching ? aws_ssm_patch_baseline.linux[0].id : null
}

output "windows_patch_group" {
  description = "Windows patch group name"
  value       = var.enable_patching && var.enable_windows_patching ? "${var.environment}-ajyal-windows" : null
}

output "linux_patch_group" {
  description = "Linux patch group name"
  value       = var.enable_patching && var.enable_linux_patching ? "${var.environment}-ajyal-linux" : null
}

output "windows_maintenance_window_id" {
  description = "Windows maintenance window ID"
  value       = var.enable_patching && var.enable_windows_patching ? aws_ssm_maintenance_window.windows[0].id : null
}

output "linux_maintenance_window_id" {
  description = "Linux maintenance window ID"
  value       = var.enable_patching && var.enable_linux_patching ? aws_ssm_maintenance_window.linux[0].id : null
}

output "patch_notifications_topic_arn" {
  description = "SNS topic ARN for patch notifications"
  value       = var.enable_patching && var.enable_patch_notifications ? aws_sns_topic.patch_notifications[0].arn : null
}

output "patch_compliance_bucket" {
  description = "S3 bucket for patch compliance reports"
  value       = var.enable_patching && var.enable_patch_compliance ? aws_s3_bucket.patch_compliance[0].id : null
}
