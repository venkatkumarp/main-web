
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
    journyx_password      = var.secret_values["journyx_password"]
    cwid_db_password           = var.secret_values["cwid_db_password"]
    clientID   = var.config_values["clientID"]
    cdnurl   = var.cdnurl
    tenantId       = var.tenantId
    redirectUri    = var.redirectUri
    code_challenge_method = var.code_challenge_method
    db_server  = var.db_server
    db_name  = var.db_name
    db_user   = var.db_user
    odbc_driver = var.odbc_driver
    journyx_url  =  var.journyx_url
    journyx_user  = var.journyx_user
  })
}
