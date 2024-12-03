data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

module "s3_bucket" {
  source                     = "./modules/s3_bucket"
  project_name               = "${local.environment}-${local.project_name}-bucket1"
  default_tags               = local.default_tags
  cloudfront_oac_id          = module.cloudfront.origin_access_control_id
  aws_account_id             = var.aws_account_id
  cloudfront_distribution_id = module.cloudfront.cloudfront_distribution_id
  environment                = local.environment
  permission_for_logs        = "Allow"
}

module "cloudfront" {
  source                = "./modules/cloudfront"
  project_name          = "${local.environment}-${local.project_name}-cdn"
  s3_bucket_domain_name = module.s3_bucket.s3_bucket_domain_name
  existing_web_acl_name = local.existing_web_acl_name
  default_tags          = local.default_tags
  environment           = local.environment
  lambda_edge_arn       = module.lambda_edge.lambda_qualified_arn
  s3_bucket_name        = module.s3_bucket.s3_bucket_name
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}


module "lambda_edge" {
  source              = "./modules/lambda_edge"
  role_name           = "${local.environment}-${local.project_name}-lambda-edge-role"
  function_name       = "${local.environment}-${local.project_name}-lambda-edge-function"
  project_name        = local.project_name
  environment         = local.environment
  default_tags        = local.default_tags
#  s3_bucket_name_edge = local.s3_bucket_name_edge
  secret_arn          = module.secrets_manager.secret_arn
  providers = {
    aws.us-east-1 = aws.us-east-1
  }

}


module "lambda_auth" {
  source                    = "./modules/lambda_auth"
  lambda_auth_role_name     = "${local.environment}-${local.project_name}-lambda-auth-role"
  lambda_auth_function_name = "${local.environment}-${local.project_name}-lambda-auth-function"
  project_name              = local.project_name
  environment               = local.environment
  default_tags              = local.default_tags
  api_gateway_execution_arn = module.api_gateway.api_execution_arn
  s3_bucket_name            = local.s3_bucket_name
}

module "api_gateway" {
  source                      = "./modules/api_gateway"
  api_gateway_name            = "${local.environment}-${local.project_name}-api-gateway"
  api_gateway_authorizer_name = "${local.environment}-${local.project_name}-api-gateway-authorizer"
  api_gateway_stage_name      = "${local.environment}-${local.project_name}-api-gateway-stage"
  project_name                = local.project_name
  environment                 = local.environment
  region                      = data.aws_region.current.name
  lambda_arn                  = module.lambda_auth.lambda_arn

}

module "lambda_gettoken" {
  source                        = "./modules/lambda_gettoken"
  gettoken_lambda_role_name     = "${local.environment}-${local.project_name}-lambda-gettoken-role"
  gettoken_lambda_function_name = "${local.environment}-${local.project_name}-lambda-gettoken-function"
  project_name                  = local.project_name
  environment                   = local.environment
  default_tags                  = local.default_tags
  secret_manager                = module.secrets_manager.secret_arn
  s3_bucket_name                = local.s3_bucket_name
}


module "secrets_manager" {
  source      = "./modules/secrets_manager"
  secret_name = "/tt${local.environment}/secret-name"
  secret_values = merge(
    local.secrets_manager,
    { cdn_url = "https://${module.cloudfront.cloudfront_distribution_domain_name}" }
  )
  environment  = local.environment
  default_tags = local.default_tags
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}
