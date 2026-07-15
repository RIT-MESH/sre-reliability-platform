variable "region" {
  type        = string
  description = "AWS region for bootstrap resources."
  default     = "us-east-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique name for the Terraform state bucket."
}

variable "lock_table_name" {
  type        = string
  description = "Name of the DynamoDB lock table."
  default     = "sre-platform-tf-locks"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in org/name form allowed to assume the OIDC role."
}
