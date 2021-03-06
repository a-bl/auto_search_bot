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

variable "env" {
  type = string
}

variable "github_repo_full_name" {
  type = string
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "telegram_token" {
  type      = string
  sensitive = true
}

variable "vpc_cidr" {
  type = string
}
