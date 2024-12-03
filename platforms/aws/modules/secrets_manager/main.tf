resource "aws_secretsmanager_secret" "ttm_secrets_name" {
  provider = aws.us-east-1
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "ttm_secrets" {
  provider = aws.us-east-1
  secret_id     = aws_secretsmanager_secret.ttm_secrets_name.id
  secret_string = jsonencode(var.secret_values)
}
