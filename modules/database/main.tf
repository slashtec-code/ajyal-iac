###############################################################################
# Database Module
# RDS MS SQL Server, PostgreSQL, OpenSearch, ElastiCache Redis
###############################################################################

locals {
  name_prefix = "${var.environment}-ajyal"
}

#------------------------------------------------------------------------------
# DB Subnet Group
#------------------------------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

#------------------------------------------------------------------------------
# MS SQL Server RDS (LMS, Communication, Dashboards DBs)
#------------------------------------------------------------------------------

resource "aws_db_instance" "mssql" {
  count = var.enable_mssql ? 1 : 0

  identifier = "${local.name_prefix}-mssql"

  engine                = "sqlserver-se"
  engine_version        = "15.00"
  license_model         = "license-included"
  instance_class        = var.mssql_instance_class
  allocated_storage     = var.mssql_allocated_storage
  max_allocated_storage = var.mssql_max_allocated_storage # Auto-scales up to 200GB
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]

  username = "admin"
  password = random_password.mssql[0].result

  multi_az                  = var.mssql_multi_az
  publicly_accessible       = false
  deletion_protection       = var.enable_deletion_protection
  skip_final_snapshot       = !var.enable_deletion_protection
  final_snapshot_identifier = var.enable_deletion_protection ? "${local.name_prefix}-mssql-final-snapshot" : null

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn

  enabled_cloudwatch_logs_exports = ["error", "agent"]

  tags = {
    Name = "${local.name_prefix}-mssql"
  }
}

resource "random_password" "mssql" {
  count   = var.enable_mssql ? 1 : 0
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "mssql" {
  count = var.enable_mssql ? 1 : 0
  name  = "${local.name_prefix}/database/mssql"

  tags = {
    Name = "${local.name_prefix}-mssql-secret"
  }
}

resource "aws_secretsmanager_secret_version" "mssql" {
  count     = var.enable_mssql ? 1 : 0
  secret_id = aws_secretsmanager_secret.mssql[0].id

  secret_string = jsonencode({
    username = "admin"
    password = random_password.mssql[0].result
    host     = aws_db_instance.mssql[0].address
    port     = 1433
  })
}

#------------------------------------------------------------------------------
# Aurora PostgreSQL (Chatbot DB) - Serverless v2
# Auto-scales, faster failover, 5x throughput vs standard PostgreSQL
#------------------------------------------------------------------------------

resource "aws_rds_cluster" "aurora_postgresql" {
  count = var.enable_postgresql ? 1 : 0

  cluster_identifier = "${local.name_prefix}-aurora-postgresql"

  engine         = "aurora-postgresql"
  engine_version = "16.4"
  engine_mode    = "provisioned"

  database_name   = "chatbot"
  master_username = "dbadmin"
  master_password = random_password.postgresql[0].result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  # Serverless v2 scaling configuration
  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_capacity
    max_capacity = var.aurora_max_capacity
  }

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"

  deletion_protection       = var.enable_deletion_protection
  skip_final_snapshot       = !var.enable_deletion_protection
  final_snapshot_identifier = var.enable_deletion_protection ? "${local.name_prefix}-aurora-final-snapshot" : null

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Name = "${local.name_prefix}-aurora-postgresql"
  }
}

resource "aws_rds_cluster_instance" "aurora_postgresql" {
  count = var.enable_postgresql ? 1 : 0

  identifier         = "${local.name_prefix}-aurora-postgresql-instance"
  cluster_identifier = aws_rds_cluster.aurora_postgresql[0].id

  instance_class = "db.serverless"
  engine         = aws_rds_cluster.aurora_postgresql[0].engine
  engine_version = aws_rds_cluster.aurora_postgresql[0].engine_version

  publicly_accessible = false

  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.rds_monitoring.arn

  tags = {
    Name = "${local.name_prefix}-aurora-postgresql-instance"
  }
}

resource "random_password" "postgresql" {
  count   = var.enable_postgresql ? 1 : 0
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "postgresql" {
  count = var.enable_postgresql ? 1 : 0
  name  = "${local.name_prefix}/database/aurora-postgresql"

  tags = {
    Name = "${local.name_prefix}-aurora-postgresql-secret"
  }
}

resource "aws_secretsmanager_secret_version" "postgresql" {
  count     = var.enable_postgresql ? 1 : 0
  secret_id = aws_secretsmanager_secret.postgresql[0].id

  secret_string = jsonencode({
    username        = "admin"
    password        = random_password.postgresql[0].result
    host            = aws_rds_cluster.aurora_postgresql[0].endpoint
    reader_endpoint = aws_rds_cluster.aurora_postgresql[0].reader_endpoint
    port            = 5432
    database        = "chatbot"
  })
}

#------------------------------------------------------------------------------
# RDS Enhanced Monitoring Role
#------------------------------------------------------------------------------

resource "aws_iam_role" "rds_monitoring" {
  name = "${local.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

#------------------------------------------------------------------------------
# OpenSearch Domain (Search engine)
#------------------------------------------------------------------------------

resource "aws_opensearch_domain" "main" {
  count       = var.enable_opensearch ? 1 : 0
  domain_name = "${local.name_prefix}-search"

  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type          = var.opensearch_instance_type
    instance_count         = var.opensearch_instance_count
    zone_awareness_enabled = false # Single AZ for preprod

    dedicated_master_enabled = false
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = var.opensearch_volume_size
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = var.kms_key_arn
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  vpc_options {
    subnet_ids         = [var.private_subnet_ids[0]]
    security_group_ids = [var.db_security_group_id]
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "admin"
      master_user_password = random_password.opensearch[0].result
    }
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch[0].arn
    log_type                 = "INDEX_SLOW_LOGS"
  }

  tags = {
    Name = "${local.name_prefix}-opensearch"
  }
}

resource "random_password" "opensearch" {
  count            = var.enable_opensearch ? 1 : 0
  length           = 16
  special          = true
  override_special = "!@#$%^&*"
}

resource "aws_cloudwatch_log_group" "opensearch" {
  count             = var.enable_opensearch ? 1 : 0
  name              = "/aws/opensearch/${local.name_prefix}-search"
  retention_in_days = 30

  tags = {
    Name = "${local.name_prefix}-opensearch-logs"
  }
}

resource "aws_cloudwatch_log_resource_policy" "opensearch" {
  count       = var.enable_opensearch ? 1 : 0
  policy_name = "${local.name_prefix}-opensearch-log-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "es.amazonaws.com"
        }
        Action = [
          "logs:PutLogEvents",
          "logs:PutLogEventsBatch",
          "logs:CreateLogStream"
        ]
        Resource = "${aws_cloudwatch_log_group.opensearch[0].arn}:*"
      }
    ]
  })
}

resource "aws_secretsmanager_secret" "opensearch" {
  count = var.enable_opensearch ? 1 : 0
  name  = "${local.name_prefix}/database/opensearch"

  tags = {
    Name = "${local.name_prefix}-opensearch-secret"
  }
}

resource "aws_secretsmanager_secret_version" "opensearch" {
  count     = var.enable_opensearch ? 1 : 0
  secret_id = aws_secretsmanager_secret.opensearch[0].id

  secret_string = jsonencode({
    username = "admin"
    password = random_password.opensearch[0].result
    endpoint = aws_opensearch_domain.main[0].endpoint
  })
}

#------------------------------------------------------------------------------
# ElastiCache Redis Subnet Group
#------------------------------------------------------------------------------

resource "aws_elasticache_subnet_group" "main" {
  count      = var.enable_redis ? 1 : 0
  name       = "${local.name_prefix}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${local.name_prefix}-redis-subnet-group"
  }
}

#------------------------------------------------------------------------------
# ElastiCache Redis Cluster
#------------------------------------------------------------------------------

resource "aws_elasticache_replication_group" "redis" {
  count = var.enable_redis ? 1 : 0

  replication_group_id = "${local.name_prefix}-redis"
  description          = "Redis cluster for ${local.name_prefix}"

  node_type            = var.redis_node_type
  num_cache_clusters   = var.redis_num_cache_nodes
  port                 = 6379
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"

  subnet_group_name  = aws_elasticache_subnet_group.main[0].name
  security_group_ids = [var.db_security_group_id]

  automatic_failover_enabled = var.redis_num_cache_nodes > 1
  multi_az_enabled           = false # Single AZ for preprod

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis[0].result

  snapshot_retention_limit = var.backup_retention_period
  snapshot_window          = "03:00-04:00"
  maintenance_window       = "sun:04:00-sun:05:00"

  tags = {
    Name = "${local.name_prefix}-redis"
  }
}

resource "random_password" "redis" {
  count   = var.enable_redis ? 1 : 0
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "redis" {
  count = var.enable_redis ? 1 : 0
  name  = "${local.name_prefix}/database/redis"

  tags = {
    Name = "${local.name_prefix}-redis-secret"
  }
}

resource "aws_secretsmanager_secret_version" "redis" {
  count     = var.enable_redis ? 1 : 0
  secret_id = aws_secretsmanager_secret.redis[0].id

  secret_string = jsonencode({
    auth_token = random_password.redis[0].result
    endpoint   = aws_elasticache_replication_group.redis[0].primary_endpoint_address
    port       = 6379
  })
}
