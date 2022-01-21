#data "aws_ami" "ubuntu" {
#  owners      = ["099720109477"] # Canonical
#  most_recent = true

#  filter {
#    name    = "name"
#    values  = ["ubuntu/images/hvm-ssd/ubuntu-*"]
#  }

#  filter {
#    name    = "architecture"
#    values  = ["x86_64"]
#  }
#}

#resource "aws_key_pair" "alpine" {
#  key_name = "alpine"
#  public_key = file("test_key_rsa.pub")
#}

#resource "aws_instance" "test" {
#  for_each                    = toset(var.avail_zones)
#  depends_on                  = [aws_route_table_association.priv]
#  ami                         = data.aws_ami.ubuntu.id
#  instance_type               = "t2.micro"
#  availability_zone           = each.key
#  subnet_id                   = aws_subnet.priv[each.key].id
#  vpc_security_group_ids      = [aws_security_group.demo.id]
#  key_name                    = aws_key_pair.alpine.key_name
#  user_data                   = templatefile("ubuntu-config.tpl", {
#                                  ssh_key=file("~/.ssh/id_rsa.pub"),
#                                  index=templatefile("index.tpl", { avail_zone=each.key })
#                                })

#  tags = {
#    Name = each.key
#  }

#  lifecycle {
#    ignore_changes = [
#      user_data
#    ]
#  }
#}

#resource "aws_instance" "test_test" {
#  depends_on                  = [aws_route_table_association.pub]
#  ami                         = data.aws_ami.ubuntu.id
#  instance_type               = "t2.micro"
#  availability_zone           = "eu-central-1a"
#  subnet_id                   = aws_subnet.pub["eu-central-1a"].id
#  vpc_security_group_ids      = [aws_security_group.demo.id]
#  key_name                    = aws_key_pair.alpine.key_name

#  tags = {
#    Name = "eu-central-1a"
#  }
#}

resource "aws_lb" "test" {
# depends_on          = [aws_instance.test]
  name                = "test"
  load_balancer_type  = "application"
  subnets             = [for subnet in aws_subnet.pub : subnet.id]
  ip_address_type     = "ipv4"
  security_groups     = [aws_security_group.demo.id]
}

resource "aws_lb_target_group" "test" {
  depends_on  = [aws_route_table_association.priv]
  name        = "test"
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id

  health_check {
    healthy_threshold   = 3
    interval            = 30
    protocol            = "HTTP"
    matcher             = 200
    timeout             = 3
    path                = "/"
    unhealthy_threshold = 2
  }
}

#resource "aws_lb_target_group_attachment" "test" {
#  for_each          = toset(var.avail_zones)
#  target_group_arn  = aws_lb_target_group.test.arn
#  target_id         = aws_instance.test[each.key].id
#  port              = 80
#}

resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type              = "forward"
    target_group_arn  = aws_lb_target_group.test.arn
  }
}
