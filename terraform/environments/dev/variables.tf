variable "region" { type = string, default = "us-east-1" }

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
  validation {
    condition     = can(regex("^10\\.|^172\\.|^192\\.168\\.", var.vpc_cidr))
    error_message = "vpc_cidr must be a private RFC1918 range."
  }
}

variable "db_name" { type = string, default = "shop" }
variable "ami_id" { type = string, description = "Amazon Linux 2023 AMI id for the app region." }
variable "ecr_image" { type = string, description = "ECR image URI to deploy, e.g. 123456789012.dkr.ecr.us-east-1.amazonaws.com/sre-platform:latest" }
variable "redis_auth_token" { type = string, sensitive = true, description = "Redis AUTH token. Provide via TF_VAR_redis_auth_token from Secrets Manager." }
variable "alert_email" { type = string, nullable = true, default = null }
