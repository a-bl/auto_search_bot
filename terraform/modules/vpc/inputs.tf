variable "app_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "subnet_prefix" {
  type    = number
  default = 24
}
