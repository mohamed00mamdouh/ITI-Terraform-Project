variable "environment" {
  type    = string
  default = "dev"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.2.0/24"]
}
variable "private_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.3.0/24"]
}
variable "key_pair_name" {
  type = string
}
variable "ssh_private_key_path" {
  type = string
} # used by provisioners
variable "app_local_path" {
  type    = string
  default = "../app_backend"
} # path to your web app files
