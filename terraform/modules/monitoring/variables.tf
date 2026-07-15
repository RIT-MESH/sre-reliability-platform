variable "name_prefix" { type = string }
variable "region" { type = string }
variable "kms_key_id" { type = string, nullable = true, default = null }
variable "alert_email" { type = string, nullable = true, default = null }
variable "log_retention_days" { type = number, default = 30 }
variable "asg_name" { type = string }
variable "alb_arn_suffix" { type = string }
variable "target_group_arn_suffix" { type = string }
variable "db_identifier" { type = string }
variable "redis_cluster_id" { type = string }
variable "cpu_high_threshold" { type = number, default = 75 }
variable "alb_5xx_threshold" { type = number, default = 20 }
variable "latency_threshold_seconds" { type = number, default = 1.0 }
variable "rds_storage_low_gb" { type = number, default = 10 }
variable "rds_cpu_high_threshold" { type = number, default = 80 }
variable "rds_connection_threshold" { type = number, default = 150 }
variable "redis_cpu_high_threshold" { type = number, default = 80 }
variable "redis_memory_low_mb" { type = number, default = 50 }
variable "tags" { type = map(string), default = {} }
