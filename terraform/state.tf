resource "aws_dynamodb_table" "state" {
  name           = "auto-search-bot"
  hash_key       = "LockID"
  write_capacity = 25
  read_capacity  = 25

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_s3_bucket" "state" {
  bucket = "auto-search-bot"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

terraform {
  backend "s3" {
    bucket         = "auto-search-bot"
    region         = "eu-central-1"
    key            = "terraform.tfstate"
    encrypt        = true
    dynamodb_table = "auto-search-bot"
  }
}
