variable "vpc_id" { type = string }
variable "env" { type = string, default = "dev" }
variable "admin_cidrs" { type = list(string), default = ["0.0.0.0/0"] } # restrict in prod
