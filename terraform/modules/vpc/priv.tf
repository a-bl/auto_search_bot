resource "aws_subnet" "priv" {
  for_each          = toset(local.avz)
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.priv_subnets[each.key]
  availability_zone = each.key

  tags = {
    Name = "${var.app_name} ${var.env} priv"
  }
}

resource "aws_eip" "eip" {
  for_each   = toset(local.avz)
  vpc        = true
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.app_name} ${var.env} priv ${each.key}"
  }
}

resource "aws_nat_gateway" "nat" {
  for_each      = toset(local.avz)
  allocation_id = aws_eip.eip[each.key].id
  subnet_id     = aws_subnet.pub[each.key].id
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name = "${var.app_name} ${var.env} priv ${each.key}"
  }
}

resource "aws_route_table" "priv" {
  for_each = toset(local.avz)
  vpc_id   = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }
}

resource "aws_route_table_association" "priv" {
  for_each       = toset(local.avz)
  subnet_id      = aws_subnet.priv[each.key].id
  route_table_id = aws_route_table.priv[each.key].id
}
