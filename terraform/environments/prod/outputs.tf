output "alb_dns_name" { value = module.compute.alb_dns_name }
output "db_endpoint" {
  value     = module.database.db_endpoint
  sensitive = true
}
output "db_secret_arn" {
  value     = module.database.db_secret_arn
  sensitive = true
}
output "redis_endpoint" { value = module.cache.redis_configuration_endpoint }
output "alert_topic_arn" { value = module.monitoring.alert_topic_arn }
output "ops_bucket" { value = module.storage.bucket_name }
output "dashboard_name" { value = module.monitoring.dashboard_name }
