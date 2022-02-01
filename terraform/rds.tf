resource "random_pet" "db_user" {
  separator = "_"

  keepers = {
    name = var.app_name
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

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [for subnet in aws_subnet.priv : subnet.id]
}

resource "aws_security_group" "db" {
  name   = "postgres"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [for subnet in concat(values(aws_subnet.priv), values(aws_subnet.pub)) : subnet.cidr_block]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [for subnet in concat(values(aws_subnet.priv), values(aws_subnet.pub)) : subnet.cidr_block]
  }
}

resource "aws_db_instance" "main" {
  engine                 = "postgres"
  engine_version         = "12.9"
  instance_class         = "db.t2.micro"
  allocated_storage      = 20
  port                   = 5432
  db_subnet_group_name   = aws_db_subnet_group.default.id
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true
  name                   = "telegram_bot_db"
  username               = random_pet.db_user.id
  password               = random_password.db_pass.result
}
