resource "aws_ecr_repository" "repo" {
  name = "final-demo"

  provisioner "local-exec" {
    working_dir = "./app/"
    command = "make"
  }
}
