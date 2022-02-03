variable "api_token" {
  type      = string
  sensitive = true
}

variable "app_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "db_name" {
  type    = string
  default = "telegram_bot_db"
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "env" {
  type = string
}

variable "priv_ids" {
  type = list(string)
}

variable "pub_ids" {
  type = list(string)
}

variable "sg_id" {
  type = string
}

variable "telegram_token" {
  type      = string
  sensitive = true
}

variable "vpc_id" {
  type = string
}
