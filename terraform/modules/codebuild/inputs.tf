variable "app_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ecr_name" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
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

variable "priv_ids" {
  type = list(string)
}

variable "sg_id" {
  type = string
}

variable "vpc_id" {
  type = string
}
