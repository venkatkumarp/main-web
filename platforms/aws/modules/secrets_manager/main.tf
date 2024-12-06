resource "aws_secretsmanager_secret" "web_secrets" {
  name        = var.secret_name
}

resource "aws_secretsmanager_secret_version" "web_secrets_version" {
  secret_id     = aws_secretsmanager_secret.web_secrets.id
  secret_string = jsonencode({
    client_secret = var.client_secret
    code_verifier = var.code_verifier
    code_challenge = var.code_challenge
  })
}