data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# One public subnet. Packer SSH from GitHub needs an Internet gateway, not NAT.
resource "aws_vpc" "packer" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = local.tags
}

resource "aws_internet_gateway" "packer" {
  vpc_id = aws_vpc.packer.id
  tags   = local.tags
}

resource "aws_subnet" "packer" {
  vpc_id                  = aws_vpc.packer.id
  cidr_block              = var.vpc_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = local.tags
}

resource "aws_route_table" "packer" {
  vpc_id = aws_vpc.packer.id
  tags   = local.tags
}

resource "aws_route" "packer_internet" {
  route_table_id         = aws_route_table.packer.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.packer.id
}

resource "aws_route_table_association" "packer" {
  subnet_id      = aws_subnet.packer.id
  route_table_id = aws_route_table.packer.id
}
