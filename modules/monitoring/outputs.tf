###############################################################################
# Monitoring Module Outputs
###############################################################################

output "alarm_sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  value       = var.enable_cloudwatch_alarms ? aws_sns_topic.alarms[0].arn : null
}

output "application_log_group" {
  description = "Application CloudWatch log group name"
  value       = aws_cloudwatch_log_group.application.name
}

output "windows_log_group" {
  description = "Windows CloudWatch log group name"
  value       = aws_cloudwatch_log_group.windows.name
}

output "linux_log_group" {
  description = "Linux CloudWatch log group name"
  value       = aws_cloudwatch_log_group.linux.name
}

output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = var.enable_cloudwatch_dashboards ? aws_cloudwatch_dashboard.main[0].dashboard_name : null
}

output "cloudtrail_arn" {
  description = "CloudTrail ARN"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
}

output "siem_queue_url" {
  description = "SIEM SQS queue URL"
  value       = var.enable_siem_integration ? aws_sqs_queue.siem[0].url : null
}

output "siem_queue_arn" {
  description = "SIEM SQS queue ARN"
  value       = var.enable_siem_integration ? aws_sqs_queue.siem[0].arn : null
}
