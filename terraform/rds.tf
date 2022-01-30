resource "aws_db_instance" "postgres" {
  allocated_storage = 20
  engine            = "postgres"
  instance_class    = "db.t2.micro"
  name              = "auto_search_bot"
  username          = "dummy"
  password          = "DUMMY"
}
