data "aws_subnet" "priv" {
  count = length(var.priv_ids)
  id    = var.priv_ids[count.index]
}

resource "random_pet" "db_user" {
  separator = "_"

  keepers = {
    name = var.app_name
    env  = var.env
  }
}

resource "random_password" "db_pass" {
  length  = 16
  lower   = true
  upper   = true
  number  = true
  special = false

  keepers = {
    user = random_pet.db_user.id
  }
}

resource "aws_db_subnet_group" "priv" {
  name       = "${var.app_name}-${var.env}"
  subnet_ids = var.priv_ids
}

resource "aws_security_group" "db" {
  name   = "postgres"
  vpc_id = var.vpc_id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [for subnet in data.aws_subnet.priv : subnet.cidr_block]
  }

  egress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [for subnet in data.aws_subnet.priv : subnet.cidr_block]
  }
}

resource "aws_db_instance" "main" {
  engine                 = "postgres"
  engine_version         = "12.9"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  port                   = var.db_port
  db_subnet_group_name   = aws_db_subnet_group.priv.id
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true
  name                   = var.db_name
  username               = random_pet.db_user.id
  password               = random_password.db_pass.result
}
