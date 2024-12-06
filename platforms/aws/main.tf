data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

module "lambda_code_bucket" {
  source             = "./modules/lambda_code_bucket"
  lambda_bucket_name = "web.${local.environment}.time-test.com"
  project_name       = local.project_name
  default_tags       = local.default_tags
  aws_account_id     = var.aws_account_id
  environment        = local.environment
}
