###############################################################################
# Compute Module Variables - Cost Optimized for PreProd
###############################################################################

variable "environment" {
  default = "preprod"
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "enable_codedeploy" {
  default = true
}

#------------------------------------------------------------------------------
# Windows Servers - Cost Optimized (t3 instead of c5)
#------------------------------------------------------------------------------

variable "enable_app_servers" {
  default = true
}

variable "app_server_instance_type" {
  default = "t3.medium" # Cost optimized
}

variable "app_server_min_size" {
  default = 1
}

variable "app_server_max_size" {
  default = 2
}

variable "app_server_desired_size" {
  default = 1
}

variable "enable_api_servers" {
  default = true
}

variable "api_server_instance_type" {
  default = "t3.medium"
}

variable "api_server_min_size" {
  default = 1
}

variable "api_server_max_size" {
  default = 2
}

variable "enable_integration_servers" {
  default = true
}

variable "integration_server_instance_type" {
  default = "t3.small"
}

variable "integration_server_min_size" {
  default = 1
}

variable "integration_server_max_size" {
  default = 2
}

variable "enable_logging_servers" {
  default = true
}

variable "logging_server_instance_type" {
  default = "t3.small"
}

variable "logging_server_min_size" {
  default = 1
}

variable "logging_server_max_size" {
  default = 1
}

#------------------------------------------------------------------------------
# Linux Servers - Cost Optimized (t3 instead of c5)
#------------------------------------------------------------------------------

# RabbitMQ - Single Instance (No ASG, No CodeDeploy)
variable "enable_rabbitmq_servers" {
  default = true
}

variable "rabbitmq_instance_type" {
  default = "t3.small" # Single instance for preprod
}

variable "enable_botpress_servers" {
  default = true
}

variable "botpress_instance_type" {
  default = "t3.small"
}

variable "botpress_min_size" {
  default = 1
}

variable "botpress_max_size" {
  default = 1
}

variable "enable_ml_servers" {
  default = true
}

variable "ml_server_instance_type" {
  default = "t3.medium"
}

variable "ml_server_min_size" {
  default = 1
}

variable "ml_server_max_size" {
  default = 1
}

variable "enable_content_servers" {
  default = true
}

variable "content_server_instance_type" {
  default = "t3.medium"
}

variable "content_server_min_size" {
  default = 1
}

variable "content_server_max_size" {
  default = 2
}

#------------------------------------------------------------------------------
# CloudFront CDN
#------------------------------------------------------------------------------

variable "enable_cloudfront" {
  default = true
}

variable "cloudfront_price_class" {
  default = "PriceClass_100" # North America and Europe only (cost optimized)
}
