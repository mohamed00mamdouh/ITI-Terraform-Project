# vpc
module "vpc" {
  source          = "./modules/vpc"
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  env             = var.environment
}

# security groups (proxy + backend + alb)
module "sg" {
  source = "./modules/sg"
  vpc_id = module.vpc.vpc_id
}

# NAT (if you want a module; can be created inside vpc module)
module "nat" {
  source         = "./modules/nat"
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnet_ids
}

# public proxies (one in each public subnet)
module "proxy_ec2" {
  source               = "./modules/ec2"
  name_prefix          = "proxy"
  instance_count       = 2
  subnet_ids           = module.vpc.public_subnet_ids
  security_group_ids   = [module.sg.proxy_sg_id]
  key_name             = var.key_pair_name
  ssh_private_key_path = var.ssh_private_key_path
  ami_filter           = { owners = ["amazon"], name_regex = "amzn2-ami-hvm-*-x86_64-gp2" }
  user_data            = file("provisioners/install-proxy.sh")
  provision_app        = true # will run remote-exec to install nginx / proxy
}

# private backend EC2s (one in each private subnet)
module "backend_ec2" {
  source               = "./modules/ec2"
  name_prefix          = "backend"
  instance_count       = 2
  subnet_ids           = module.vpc.private_subnet_ids
  security_group_ids   = [module.sg.backend_sg_id]
  key_name             = var.key_pair_name
  ssh_private_key_path = var.ssh_private_key_path
  ami_filter           = { owners = ["amazon"], name_regex = "amzn2-ami-hvm-*-x86_64-gp2" }
  provision_app        = false # we'll copy files with file provisioner and run remote-exec
  # this example copies your local app folder to the backend
  copy_app = {
    local_path  = var.app_local_path
    remote_path = "/home/ec2-user/app"
  }
  # instruct the module to use jump_host (public proxy) for connecting to private hosts
  jump_host = module.proxy_ec2.public_ips[0] # example - adjust for multi-hop
  jump_user = "ec2-user"
}

# ALBs
module "albs" {
  source             = "./modules/alb"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  proxy_targets      = module.proxy_ec2.instance_ids
  backend_targets    = module.backend_ec2.instance_ids
  security_group_ids = [module.sg.alb_sg_id]
}

# Write all public ips to local file using null_resource + local-exec
resource "null_resource" "write_ips" {
  triggers = {
    proxy_public_ips   = join(",", module.proxy_ec2.public_ips)
    backend_public_ips = join(",", coalesce(module.backend_ec2.public_ips, []))
  }

  provisioner "local-exec" {
    command     = <<EOT
echo "proxy ${join(" ", module.proxy_ec2.public_ips)} backend ${join(" ", coalesce(module.backend_ec2.public_ips, []))}" > ./all-ips.txt
# produce desired format: public-ip1 1.1.1.1 public-ip2 2.2.2.2
# you can format however you want; here's a simple flat output:
echo "${join(" ", module.proxy_ec2.public_ips)} ${join(" ", coalesce(module.backend_ec2.public_ips, []))}" > ./all-ips.txt
EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
