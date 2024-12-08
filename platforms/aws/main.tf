data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

/*module "lambda_code_bucket" {
  source             = "./modules/lambda_code_bucket"
  lambda_bucket_name = "web.${local.environment}.time-test.com"
  project_name       = local.project_name
  default_tags       = local.default_tags
  aws_account_id     = var.aws_account_id
  environment        = local.environment
}
module "secrets_manager" {
  source           = "./modules/secrets_manager"
  secret_name      = "web-secrets-${local.environment}"
  project_name     = local.project_name
  default_tags     = local.default_tags
  environment      = local.environment
  aws_account_id     = var.aws_account_id
  client_secret    = local.web_secrets[var.aws_account_id].client_secret
  code_verifier    = local.web_secrets[var.aws_account_id].code_verifier
  code_challenge   = local.web_secrets[var.aws_account_id].code_challenge              
}*/

module "secret_manager" {
  source        = "./modules/secret_manager"
  secret_name   = "${local.environment}-client-secret"
  #description   = "Secrets for ${local.environment} environment"
  secret_values = {
    client_secret  = var.client_secret
    code_verifier  = var.code_verifier
    code_challenge = var.code_challenge
  }
}