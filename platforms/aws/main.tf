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

module "secrets_manager" {
  source        = "./modules/secrets_manager"
  # secret_name   = local.secret_name
  secret_name   = local.secrets.secret_name
  #aws_account_id     = var.aws_account_id
  project_name     = local.project_name
  environment      = local.environment
  default_tags     = local.default_tags
  clientID = local.secrets.clientID
  cdnurl  =  local.secrets.cdnurl
  tenantId    = local.secrets.tenantId
  redirectUri = local.secrets.redirectUri
  secret_values = {
    client_secret  = var.client_secret
    code_verifier  = var.code_verifier
    code_challenge = var.code_challenge
  }
}

module "lambda_gettoken" {
  source                        = "./modules/lambda_gettoken"
  gettoken_lambda_role_name     = "${local.environment}-${local.project_name}-lambda-gettoken-role"
  gettoken_lambda_function_name = "${local.environment}-${local.project_name}-lambda-gettoken-function"
  project_name                  = local.project_name
  environment                   = local.environment
  default_tags                  = local.default_tags
  secret_manager                = module.secrets_manager.secret_arn
  #secret_arn   = module.secrets_manager.secret_arn
  s3_bucket_name                = local.s3_bucket_name
  clientID     = module.secrets_manager.secret_values["clientID"]
  cdnurl       = module.secrets_manager.secret_values["cdnurl"]
  tenantId     = module.secrets_manager.secret_values["tenantId"]
  redirectUri  = module.secrets_manager.secret_values["redirectUri"]
  client_secret = module.secrets_manager.secret_values["client_secret"]
  code_verifier = module.secrets_manager.secret_values["code_verifier"]
  code_challenge = module.secrets_manager.secret_values["code_challenge"]
}
