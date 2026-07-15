variable "name_prefix" { type = string }
variable "cidr" { type = string, default = "10.20.0.0/16" }
variable "azs" { type = list(string), default = ["us-east-1a", "us-east-1b"] }
variable "single_nat_gateway" { type = bool, default = true }
variable "tags" { type = map(string), default = {} }
