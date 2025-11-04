output "proxy_public_ips" {
  value = module.proxy_ec2.public_ips
}

output "backend_private_ips" {
  value = module.backend_ec2.private_ips
}
