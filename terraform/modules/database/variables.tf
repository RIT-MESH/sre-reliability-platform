variable "name_prefix" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "db_sg_id" { type = string }
variable "kms_key_id" { type = string, nullable = true, default = null }
variable "db_name" { type = string, default = "shop" }
variable "username" { type = string, default = "shop_admin" }
variable "engine_version" { type = string, default = "16.2" }
variable "engine_version_major" { type = string, default = "16" }
variable "instance_class" { type = string, default = "db.t3.medium" }
variable "allocated_storage" { type = number, default = 50 }
variable "max_allocated_storage" { type = number, default = 200 }
variable "multi_az" { type = bool, default = true }
variable "backup_retention_days" { type = number, default = 7 }
variable "deletion_protection" { type = bool, default = true }
variable "final_snapshot_on_delete" { type = bool, default = true }
variable "performance_insights" { type = bool, default = true }
variable "enhanced_monitoring" { type = bool, default = false }
variable "secret_recovery_days" { type = number, default = 7 }
variable "tags" { type = map(string), default = {} }
