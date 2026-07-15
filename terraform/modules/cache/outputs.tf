output "redis_primary_endpoint" {
  value     = aws_elasticache_replication_group.this.primary_endpoint_address
  sensitive = true
}
output "redis_configuration_endpoint" { value = aws_elasticache_replication_group.this.configuration_endpoint_address }
output "redis_port" { value = aws_elasticache_replication_group.this.port }
output "replication_group_id" { value = aws_elasticache_replication_group.this.id }
