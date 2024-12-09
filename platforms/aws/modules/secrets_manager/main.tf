/*resource "aws_secretsmanager_secret" "web_secrets" {
  name        = var.secret_name
}

resource "aws_secretsmanager_secret_version" "web_secrets_version" {
  secret_id     = aws_secretsmanager_secret.web_secrets.id
  secret_string = jsonencode({
    client_secret = var.client_secret
    code_verifier = var.code_verifier
    code_challenge = var.code_challenge
  })
}*/

resource "aws_secretsmanager_secret" "secret" {
  name        = var.secret_name
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id     = aws_secretsmanager_secret.secret.id
   # secret_string = jsonencode(var.secret_values)
  secret_string = jsonencode({
    client_secret  = var.secret_values["client_secret"]
    code_verifier  = var.secret_values["code_verifier"]
    code_challenge = var.secret_values["code_challenge"]
    tenantId       = var.tenantId
    redirectUri    = var.redirectUri
  })
}
