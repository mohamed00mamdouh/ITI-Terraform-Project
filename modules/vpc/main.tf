resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = { Name = "${var.env}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.env}-igw" }
}

resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)
  vpc_id = aws_vpc.this.id
  cidr_block = each.value
  availability_zone = element(data.aws_availability_zones.available.names, index(keys(toset(var.public_subnets)), each.key))
  map_public_ip_on_launch = true
  tags = { Name = "${var.env}-public-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each = toset(var.private_subnets)
  vpc_id = aws_vpc.this.id
  cidr_block = each.value
  map_public_ip_on_launch = false
  tags = { Name = "${var.env}-private-${each.key}" }
}

data "aws_availability_zones" "available" {}

output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_ids" { value = [for s in aws_subnet.public : s.id] }
output "private_subnet_ids" { value = [for s in aws_subnet.private : s.id] }
