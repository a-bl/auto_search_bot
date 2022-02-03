resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_subnet" "pub" {
  for_each                = toset(local.avz)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.pub_subnets[each.key]
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.app_name} ${var.env} pub"
  }
}

resource "aws_route_table_association" "pub" {
  for_each       = toset(local.avz)
  subnet_id      = aws_subnet.pub[each.key].id
  route_table_id = aws_route_table.pub.id
}
