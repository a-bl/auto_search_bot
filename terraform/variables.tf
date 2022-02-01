variable "app_name" {
  type    = string
  default = "auto_search_bot"
}

variable "avail_zones" {
  type    = list(string)
  default = ["eu-central-1a", "eu-central-1b"]
}

variable "telegram_token" {
  type      = string
  sensitive = true
}

variable "github_token" {
  type      = string
  sensitive = true
}
