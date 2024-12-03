output "secret_arn" {
  value = aws_secretsmanager_secret.ttm_secrets_name.arn
}
