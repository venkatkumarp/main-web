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
  backend "s3" {}
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
    key_prefixes = ["bayer:", "mon:"]
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
    "440744244651" = "dev"
    "423623838336" = "prod"
  }

  suffixes = {
    "440744244651" = "dev"
    "423623838336" = "prod"
  }

  aws_region = "eu-central-1"
  aws_infra_deploy_role = "arn:aws:iam::${var.aws_account_id}:role/infra-dev-deploy-role"

  # Lookup lambda function name and ECR repo name based on the account ID
  lambda_function_name = lookup({
    "440744244651" = "docker-lambda"
    "423623838336" = "tfprodbc"
  }, var.aws_account_id, "null")  

  ecr_repo_name = lookup({
    "440744244651" = "test-repo"
    "423623838336" = "tfprodbc"
  }, var.aws_account_id, "null") 
}

################################################################
##                                                            ##
##  External Data Source for Backend Build Process            ##
##                                                            ##
################################################################

data "external" "backend_package" {
  program = ["bash", "${path.module}/backend-build.sh"]

  query = {
    environment        = local.environment
    lambda_function_name = local.lambda_function_name
    ecr_repo_name        = local.ecr_repo_name
  }
}

################################################################
##                                                            ##
##  Outputs from the Frontend Build Process                   ##
##                                                            ##
###############################################################

output "docker_image_status" {
  value       = data.external.backend_package.result.status  # Corrected reference
  description = "Status of the Docker image build and deployment"
}

output "lambda_function_name" {
  value       = local.lambda_function_name[var.aws_account_id]  # Access specific lambda name
  description = "Name of the Lambda function used for deployment"
}

output "image_uri" {
  value       = data.external.backend_package.result.image_uri  # Corrected reference
  description = "URI of the Docker image pushed to ECR"
}

output "ecr_repo_name" {
  value       = local.ecr_repo_name[var.aws_account_id]  # Access specific ECR repo name
  description = "The name of the ECR repository"
}
