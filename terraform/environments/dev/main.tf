locals {
  name_prefix = "sre-dev"
  common_tags = {
    Project     = "sre-reliability-platform"
    Environment = "dev"
    ManagedBy   = "terraform"
    Repo        = "sre-reliability-platform"
  }
  azs = ["${var.region}a", "${var.region}b"]
}

module "networking" {
  source             = "../../modules/networking"
  name_prefix        = local.name_prefix
  cidr               = var.vpc_cidr
  azs                = local.azs
  single_nat_gateway = true # cost-optimised for dev
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
  instance_class        = "db.t3.medium"
  multi_az              = true
  backup_retention_days = 1
  deletion_protection   = false
  enhanced_monitoring   = false
  tags                  = local.common_tags
}

module "cache" {
  source             = "../../modules/cache"
  name_prefix        = local.name_prefix
  private_subnet_ids = module.networking.private_subnet_ids
  redis_sg_id        = module.security.redis_sg_id
  node_type          = "cache.t3.micro"
  num_cache_clusters = 1
  auth_token         = var.redis_auth_token
  tags               = local.common_tags
}

module "compute" {
  source             = "../../modules/compute"
  name_prefix        = local.name_prefix
  environment        = "dev"
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  alb_sg_id          = module.security.alb_sg_id
  app_sg_id          = module.security.app_sg_id
  ami_id             = var.ami_id
  instance_type      = "t3.small"
  min_size           = 2
  desired_size       = 2
  max_size           = 4
  cpu_target         = 65
  ecr_image          = var.ecr_image
  db_host            = module.database.db_address
  db_secret_arn      = module.database.db_secret_arn
  redis_host         = module.cache.redis_configuration_endpoint
  certificate_arn    = null
  tags               = local.common_tags
}

module "monitoring" {
  source                  = "../../modules/monitoring"
  name_prefix             = local.name_prefix
  region                  = var.region
  alert_email             = var.alert_email
  asg_name                = module.compute.asg_name
  alb_arn_suffix          = module.compute.alb_arn_suffix
  target_group_arn_suffix = module.compute.target_group_arn_suffix
  db_identifier           = module.database.db_identifier
  redis_cluster_id        = module.cache.replication_group_id
  tags                    = local.common_tags
}
