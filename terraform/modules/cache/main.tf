terraform { required_version = ">= 1.7.0" }

resource "aws_elasticache_subnet_group" "this" {
  name        = "${var.name_prefix}-redis-subnet-group"
  description = "Private subnets for ${var.name_prefix} Redis"
  subnet_ids  = var.private_subnet_ids
  tags        = var.tags
}

resource "aws_elasticache_parameter_group" "this" {
  name   = "${var.name_prefix}-redis-pg"
  family = "redis7"
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
  tags = var.tags
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id          = "${var.name_prefix}-redis"
  description                   = "${var.name_prefix} Redis cache"
  node_type                     = var.node_type
  num_cache_clusters            = var.num_cache_clusters
  subnet_group_name             = aws_elasticache_subnet_group.this.name
  security_group_ids            = [var.redis_sg_id]
  parameter_group_name          = aws_elasticache_parameter_group.this.name
  automatic_failover_enabled    = var.num_cache_clusters > 1
  multi_az_enabled              = var.num_cache_clusters > 1
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  auth_token                    = var.auth_token # provide via a Secrets Manager secret in production
  engine                        = "redis"
  engine_version                = var.engine_version
  maintenance_window            = "sun:05:30-sun:06:30"
  snapshot_retention_limit      = var.snapshot_retention_days
  snapshot_window               = "04:00-05:00"
  port                          = 6379
  tags                          = merge(var.tags, { Name = "${var.name_prefix}-redis" })
}
