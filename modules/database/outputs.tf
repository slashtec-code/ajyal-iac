###############################################################################
# Database Module Outputs
###############################################################################

output "mssql_endpoint" {
  description = "MS SQL Server endpoint"
  value       = var.enable_mssql ? aws_db_instance.mssql[0].address : null
}

output "mssql_port" {
  description = "MS SQL Server port"
  value       = var.enable_mssql ? aws_db_instance.mssql[0].port : null
}

output "mssql_secret_arn" {
  description = "MS SQL Server secret ARN"
  value       = var.enable_mssql ? aws_secretsmanager_secret.mssql[0].arn : null
}

output "aurora_postgresql_endpoint" {
  description = "Aurora PostgreSQL writer endpoint"
  value       = var.enable_postgresql ? aws_rds_cluster.aurora_postgresql[0].endpoint : null
}

output "aurora_postgresql_reader_endpoint" {
  description = "Aurora PostgreSQL reader endpoint"
  value       = var.enable_postgresql ? aws_rds_cluster.aurora_postgresql[0].reader_endpoint : null
}

output "aurora_postgresql_port" {
  description = "Aurora PostgreSQL port"
  value       = var.enable_postgresql ? aws_rds_cluster.aurora_postgresql[0].port : null
}

output "aurora_postgresql_secret_arn" {
  description = "Aurora PostgreSQL secret ARN"
  value       = var.enable_postgresql ? aws_secretsmanager_secret.postgresql[0].arn : null
}

output "opensearch_endpoint" {
  description = "OpenSearch endpoint"
  value       = var.enable_opensearch ? aws_opensearch_domain.main[0].endpoint : null
}

output "opensearch_secret_arn" {
  description = "OpenSearch secret ARN"
  value       = var.enable_opensearch ? aws_secretsmanager_secret.opensearch[0].arn : null
}

output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = var.enable_redis ? aws_elasticache_replication_group.redis[0].primary_endpoint_address : null
}

output "redis_port" {
  description = "Redis port"
  value       = var.enable_redis ? 6379 : null
}

output "redis_secret_arn" {
  description = "Redis secret ARN"
  value       = var.enable_redis ? aws_secretsmanager_secret.redis[0].arn : null
}

#------------------------------------------------------------------------------
# Outputs for Monitoring
#------------------------------------------------------------------------------

output "aurora_cluster_id" {
  description = "Aurora PostgreSQL cluster identifier for monitoring"
  value       = var.enable_postgresql ? aws_rds_cluster.aurora_postgresql[0].cluster_identifier : null
}

output "mssql_instance_id" {
  description = "MSSQL RDS instance identifier for monitoring"
  value       = var.enable_mssql ? aws_db_instance.mssql[0].identifier : null
}

output "opensearch_domain_name" {
  description = "OpenSearch domain name for monitoring"
  value       = var.enable_opensearch ? aws_opensearch_domain.main[0].domain_name : null
}

output "redis_cluster_id" {
  description = "Redis cluster ID for monitoring"
  value       = var.enable_redis ? aws_elasticache_replication_group.redis[0].id : null
}
