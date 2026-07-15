variable "region" { type = string, default = "us-east-1" }

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
  validation {
    condition     = can(regex("^10\\.|^172\\.|^192\\.168\\.", var.vpc_cidr))
    error_message = "vpc_cidr must be a private RFC1918 range."
  }
}

variable "db_name" { type = string, default = "shop" }
variable "ami_id" { type = string, description = "Amazon Linux 2023 AMI id for the app region." }
variable "ecr_image" { type = string, description = "ECR image URI to deploy." }
variable "redis_auth_token" { type = string, sensitive = true, description = "Redis AUTH token via TF_VAR_redis_auth_token / Secrets Manager." }
variable "certificate_arn" { type = string, nullable = true, default = null, description = "ACM certificate ARN for the HTTPS listener." }
variable "alert_email" { type = string, nullable = true, default = null }
