variable "name_prefix" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "redis_sg_id" { type = string }
variable "node_type" { type = string, default = "cache.t3.micro" }
variable "num_cache_clusters" { type = number, default = 2 }
variable "engine_version" { type = string, default = "7.1" }
variable "snapshot_retention_days" { type = number, default = 7 }
variable "auth_token" { type = string, sensitive = true, description = "AUTH token; fetch from Secrets Manager and pass as a sensitive variable." }
variable "tags" { type = map(string), default = {} }
