# should be provided in a .env file, see .env.example
variable "cloudflare_email" {}
variable "cloudflare_apikey" {}
variable "cloudflare_account_id" {}
variable "cloudflare_zone" {}
variable "public_key_path" {}
variable "private_key_path" {}
variable "ssh_allowed_CIDR" {}
variable "domain_name" {}

variable "instance_type" {
  description = "Instance size to provision (minimum t3a.small)"
  default     = "t3a.small"
}

variable "root_vol_size" {
  description = "Size of the root volume"
  default     = 25
}

variable "instance_name" {
  description = "Name of the instance"
  default     = "platform"
}
