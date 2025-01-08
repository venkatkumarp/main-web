###############################################
##                                           ##
##  Variables Definition                     ##
##                                           ##
###############################################

variable "aws_account_id" {
  type        = string
  description = "Account ID AWS"
}

###############################################
##                                           ##
##  Provider Configuration for AWS           ##
##                                           ##
###############################################

terraform {
  backend "s3" {
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.41.0"
    }
  }
}

locals {
  default_tags = {
    ProjectName = local.project_name
    managed_by  = "terraform"
    Repository  = "https://github.com/bayer-int/ph-rd-time-tracking-web"
  }
}

provider "aws" {
  region = local.aws_region
  ignore_tags {
    key_prefixes = [
      "bayer:",
      "mon:"
    ]
  }
  assume_role {
    role_arn = local.aws_infra_deploy_role
  }
  default_tags {
    tags = local.default_tags
  }
}


###############################################
##                                           ##
##  Local Variables Configuration            ##
##                                           ##
###############################################


locals {

  project_name = "time-tracking"

  environment        = lookup(local.environments, var.aws_account_id, "none")
  environment_suffix = lookup(local.suffixes, var.aws_account_id, "")

  environments = {
    "590183961751" = "dev"
  }

  suffixes = {
    "590183961751" = "dev"
  }

  aws_region = "eu-central-1"


  aws_infra_deploy_role = "arn:aws:iam::${var.aws_account_id}:role/infra-dev-deploy-role"

  lambda_function_names = lookup({
    "590183961751" = "dev-time-tracking-fastapi-function"
  }, var.aws_account_id, null)

  ecr_repo_names = lookup({
    "590183961751" = "dev-time-tracking-ecr"
  }, var.aws_account_id, null)

  image_tags = lookup({
    "590183961751" = "api-latest"
  }, var.aws_account_id, null)

}

################################################################
##                                                            ##
##  External Data Source for Backend Build Process            ##
##                                                            ##
################################################################

data "external" "backend_deploy" {
  program = ["bash", "${path.module}/backend-build.sh"]

  query = {
    environment          = local.environment
    lambda_function_name = local.lambda_function_names
    ecr_repo_name        = local.ecr_repo_names
    ecr_registry         = "${var.aws_account_id}.dkr.ecr.${local.aws_region}.amazonaws.com"
    image_tag            = local.image_tags
    region               = local.aws_region
  }
}

################################################################
##                                                            ##
##  Outputs from the Frontend Build Process                   ##
##                                                            ##
################################################################

output "lambda_function_name" {
  value = data.external.backend_deploy.result.lambda_function
}

output "ecr_repo_name" {
  value = data.external.backend_deploy.result.ecr_repo
}

output "deployment_environment" {
  value = data.external.backend_deploy.result.environment
}

output "ecr_registry" {
  value = data.external.backend_deploy.result.ecr_registry
}

output "image_tag" {
  value = data.external.backend_deploy.result.image_tag
}

output "aws_region" {
  value = data.external.backend_deploy.result.aws_region
}
