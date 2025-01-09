data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

###################################

module "secrets_manager" {
  source = "./modules/secrets_manager"
  secrets = {
    "${local.secrets.web_secrets}" = {
      environment           = local.environment
      default_tags          = local.default_tags
      project_name          = local.project_name
      secret_values = {
        cdnurl  =  local.secrets.cdnurl
        tenantId    = local.secrets.tenantId
        redirectUri = local.secrets.redirectUri
        code_challenge_method = local.secrets.code_challenge_method
        client_secret  = var.client_secret
        code_verifier  = var.code_verifier
        code_challenge = var.code_challenge
      }
    }

    "${local.cwid_db_secrets}" = {
      description = "Secret for cwid db"
      secret_values = {
        CWID_DB_SERVER = var.CWID_DB_SERVER
        CWID_DATABASE  = var.CWID_DATABASE
        CWID_DB_USERNAME = var.CWID_DB_USERNAME
        CWID_DB_PASSWORD = var.CWID_DB_PASSWORD
        CWID_DB_DRIVER = var.CWID_DB_DRIVER

        #db_server = var.db_server 
        #database_name = var.database_name
        #db_user = var.db_user
        #db_password = var.db_password
        #db_driver = var.db_driver

      }
    }
    "${local.sap_hana_secrets}" = {
      description = "Secret for sap hana secrets"
      secret_values = {
        #sapuser = var.sapuser
        #sapid = var.sapid
        db_username = var.db_username
        db_password = var.db_password
        db_url = var.db_url
        db_table = var.db_table
        driver_name = var.driver_name
        s3_bucket_name = var.s3_bucket_name
      }
    }

    "${local.journyx_secrets}" = {
      description = "Secret  for journyx secrets"
      secret_values = {
        JXURL = var.JXURL
        JOURNYX_USER = var.JOURNYX_USER
        JOURNYX_PASSWORD = var.JOURNYX_PASSWORD
      }
    }
  }
}





###################################
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

##working below one
/*module "secrets_manager" {
  source        = "./modules/secrets_manager"
  # secret_name   = local.secret_name
  secret_name   = local.secrets.secret_name
  #aws_account_id     = var.aws_account_id
  project_name     = local.project_name
  environment      = local.environment
  default_tags     = local.default_tags

  cdnurl  =  local.secrets.cdnurl
  tenantId    = local.secrets.tenantId
  redirectUri = local.secrets.redirectUri
  code_challenge_method = local.secrets.code_challenge_method
  db_server  = local.secrets.db_server
  db_name  =  local.secrets.db_name
  db_user  = local.secrets.db_user
  odbc_driver = local.secrets.odbc_driver
  journyx_url = local.secrets.journyx_url
  journyx_user = local.secrets.journyx_user

  secret_values = {
    client_secret  = var.client_secret
    code_verifier  = var.code_verifier
    code_challenge = var.code_challenge
    journyx_password = var.journyx_password
    cwid_db_password = var.cwid_db_password
    clientid = var.clientid
    
  }
}
output "clientid" {
  value = var.clientid
}*/
module "lambda_gettoken" {
  source                        = "./modules/cloudfront/lambda_gettoken"
  #commit_id    = var.commit_id
  gettoken_lambda_role_name     = "${local.environment}-${local.project_name}-lambda-gettoken-role"
  gettoken_lambda_function_name = "${local.environment}-${local.project_name}-lambda-gettoken-function"
  project_name                  = local.project_name
  environment                   = local.environment
  default_tags                  = local.default_tags
  #secret_manager                = module.secrets_manager.secret_arn
  secret_manager                = module.secrets_manager.secret_arn[local.secrets.web_secrets]
  ##web_secrets = local.secrets.web_secrets
  #secret_arn   = module.secrets_manager.secret_arn
  s3_bucket_name                = local.s3_bucket_name


  clientID     = local.secrets.clientID
  cdnurl       = local.secrets.cdnurl
  tenantId     = local.secrets.tenantId
  redirectUri  = local.secrets.redirectUri
  code_verifier = var.code_verifier
  code_challenge = var.code_challenge
  code_challenge_method = local.secrets.code_challenge_method
}
