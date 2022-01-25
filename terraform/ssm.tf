resource "aws_ssm_parameter" "telegram_token" {
  name  = "telegram_token"
  type  = "SecureString"
  value = var.telegram_token
  tier  = "Standard"
}
