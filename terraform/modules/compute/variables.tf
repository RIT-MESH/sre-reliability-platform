variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "app_sg_id" { type = string }
variable "app_port" { type = number, default = 8000 }
variable "ami_id" { type = string, description = "Amazon Linux 2023 AMI id (data-source or hard-coded per region)." }
variable "instance_type" { type = string, default = "t3.small" }
variable "ebs_volume_size" { type = number, default = 20 }
variable "min_size" { type = number, default = 2 }
variable "desired_size" { type = number, default = 2 }
variable "max_size" { type = number, default = 6 }
variable "cpu_target" { type = number, default = 60 }
variable "enable_alb_request_scaling" { type = bool, default = false }
variable "alb_requests_per_target" { type = number, default = 1000 }
variable "certificate_arn" { type = string, nullable = true, default = null }
variable "ecr_image" { type = string, description = "Full ECR image URI to run, e.g. acct.dkr.ecr.region.amazonaws.com/sre-platform:latest" }
variable "db_host" { type = string }
variable "db_secret_arn" { type = string, description = "Secrets Manager ARN holding DB credentials." }
variable "redis_host" { type = string }
variable "workers" { type = number, default = 4 }
variable "tags" { type = map(string), default = {} }
