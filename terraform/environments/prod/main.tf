locals {
  name_prefix = "sre-prod"
  common_tags = {
    Project     = "sre-reliability-platform"
    Environment = "prod"
    ManagedBy   = "terraform"
    Repo        = "sre-reliability-platform"
  }
  azs = ["${var.region}a", "${var.region}b", "${var.region}c"]
}

module "networking" {
  source             = "../../modules/networking"
  name_prefix        = local.name_prefix
  cidr               = var.vpc_cidr
  azs                = local.azs
  single_nat_gateway = false # HA: one NAT gateway per AZ in prod
  tags               = local.common_tags
}

module "security" {
  source      = "../../modules/security"
  name_prefix = local.name_prefix
  vpc_id      = module.networking.vpc_id
  vpc_cidr    = module.networking.vpc_cidr
  tags        = local.common_tags
}

module "storage" {
  source      = "../../modules/storage"
  bucket_name = "${local.name_prefix}-ops"
  tags        = local.common_tags
}

module "database" {
  source                = "../../modules/database"
  name_prefix           = local.name_prefix
  private_subnet_ids    = module.networking.private_subnet_ids
  db_sg_id              = module.security.db_sg_id
  db_name               = var.db_name
  instance_class        = "db.r6g.large" # prod: memory-optimised
  multi_az              = true
  backup_retention_days = 30
  deletion_protection   = true
  enhanced_monitoring   = true
  tags                  = local.common_tags
}

module "cache" {
  source             = "../../modules/cache"
  name_prefix        = local.name_prefix
  private_subnet_ids = module.networking.private_subnet_ids
  redis_sg_id        = module.security.redis_sg_id
  node_type          = "cache.r6g.large"
  num_cache_clusters = 2 # prod: multi-AZ failover
  auth_token         = var.redis_auth_token
  tags               = local.common_tags
}

module "compute" {
  source                     = "../../modules/compute"
  name_prefix                = local.name_prefix
  environment                = "prod"
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  private_subnet_ids         = module.networking.private_subnet_ids
  alb_sg_id                  = module.security.alb_sg_id
  app_sg_id                  = module.security.app_sg_id
  ami_id                     = var.ami_id
  instance_type              = "t3.medium"
  min_size                   = 3
  desired_size               = 3
  max_size                   = 12
  cpu_target                 = 55
  enable_alb_request_scaling = true
  alb_requests_per_target    = 800
  ecr_image                  = var.ecr_image
  db_host                    = module.database.db_address
  db_secret_arn              = module.database.db_secret_arn
  redis_host                 = module.cache.redis_configuration_endpoint
  certificate_arn            = var.certificate_arn
  tags                       = local.common_tags
}

module "monitoring" {
  source                  = "../../modules/monitoring"
  name_prefix             = local.name_prefix
  region                  = var.region
  alert_email             = var.alert_email
  log_retention_days      = 90
  asg_name                = module.compute.asg_name
  alb_arn_suffix          = module.compute.alb_arn_suffix
  target_group_arn_suffix = module.compute.target_group_arn_suffix
  db_identifier           = module.database.db_identifier
  redis_cluster_id        = module.cache.replication_group_id
  tags                    = local.common_tags
}
