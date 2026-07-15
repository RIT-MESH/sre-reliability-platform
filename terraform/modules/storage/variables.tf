variable "bucket_name" { type = string }
variable "kms_key_id" { type = string, nullable = true, default = null }
variable "force_destroy" { type = bool, default = false }
variable "tags" { type = map(string), default = {} }
