output "vpc_id" {
  value = aws_vpc.main.id
}

output "pub_ids" {
  value = [for subnet in aws_subnet.pub : subnet.id]
}

output "priv_ids" {
  value = [for subnet in aws_subnet.priv : subnet.id]
}

output "sg_id" {
  value = aws_default_security_group.app.id
}
