##############################################
#                                           ##
#  Variables Definition                     ##
# #                                          ##
##############################################

variable "aws_account_id" {
  type        = string
  description = "Account ID AWS"
}

##############################################
#                                           ##
#  Provider Configuration for AWS           ##
#                                           ##
##############################################

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


##############################################
#                                           ##
#  Local Variables Configuration            ##
#                                           ##
##############################################


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


  bucket_names = {
    "440744244651" = "web.dev.times-tracking.int.venkat.com"
    "423623838336" = "tfprodbc"
  }
  bucket_name = lookup(local.bucket_names, var.aws_account_id, "invalid-bucket")
}



###############################################################
#                                                            ##
#  External Data Source for Frontend Build Process           ##
#                                                            ##
###############################################################

data "external" "frontend_build" {
  program = ["bash", "${path.module}/frontend-build.sh"]
  query = {
    ENVIRONMENT    = local.environment
    S3_BUCKET_NAME = local.bucket_name
    TF_COMMAND = terraform.workspace == "default" ? coalesce(terraform.workspace, "plan") : ""
  }
}

###############################################################
#                                                            ##
#  Outputs from the Frontend Build Process                   ##
#                                                            ##
###############################################################

output "build_status" {
  value = data.external.frontend_build.result.status
}

output "uploaded_files" {
  value = split(",", data.external.frontend_build.result.uploaded_files)
}

