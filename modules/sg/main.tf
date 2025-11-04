# Proxy security group (public)
resource "aws_security_group" "proxy_sg" {
  name = "${var.env}-proxy-sg"
  vpc_id = var.vpc_id
  description = "Allow HTTP/HTTPS and SSH"
  ingress {
    from_port = 80; to_port = 80; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443; to_port = 443; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22; to_port = 22; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

# Backend security group (private) - allow only from proxies and ALB internal
resource "aws_security_group" "backend_sg" {
  name = "${var.env}-backend-sg"
  vpc_id = var.vpc_id
  description = "Allow application traffic from internal proxies"
  ingress {
    from_port = 5000; to_port = 5000; protocol = "tcp"; security_groups = [aws_security_group.proxy_sg.id] # example port
  }
  ingress {
    from_port = 22; to_port = 22; protocol = "tcp"; cidr_blocks = var.admin_cidrs
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

# ALB SG
resource "aws_security_group" "alb_sg" {
  name = "${var.env}-alb-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port = 80; to_port = 80; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"]
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

output "proxy_sg_id" { value = aws_security_group.proxy_sg.id }
output "backend_sg_id" { value = aws_security_group.backend_sg.id }
output "alb_sg_id" { value = aws_security_group.alb_sg.id }
