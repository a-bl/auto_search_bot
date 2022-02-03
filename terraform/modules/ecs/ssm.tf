resource "aws_ssm_parameter" "telegram_token" {
  name  = "telegram_token"
  type  = "SecureString"
  value = var.telegram_token
  tier  = "Standard"
}

resource "aws_ssm_parameter" "api_token" {
  name  = "api_token"
  type  = "SecureString"
  value = var.api_token
  tier  = "Standard"
}

resource "aws_ssm_parameter" "db_pass" {
  name        = "db_pass"
  description = "Password for ${random_pet.db_user.id}"
  type        = "SecureString"
  value       = random_password.db_pass.result
  tier        = "Standard"
}
