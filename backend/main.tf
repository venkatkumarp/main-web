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
    "440744244651" = "dev"
  }

  suffixes = {
    "440744244651" = "dev"
  }

  aws_region = "eu-central-1"


  aws_infra_deploy_role = "arn:aws:iam::${var.aws_account_id}:role/infra-dev-deploy-role"

  bucket_names = {
    "440744244651" = "web.dev.times-tracking.int.venkat.com"
  }
  bucket_name = lookup(local.bucket_names, var.aws_account_id, "invalid-bucket")

}

################################################################
##                                                            ##
##  External Data Source for Backend Build Process            ##
##                                                            ##
################################################################

data "external" "backend_package" {
  program = ["bash", "${path.module}/backend-build.sh"]

  query = {
    environment = local.environment
    bucket_name = local.bucket_name
    output_path = "${path.module}/backend.zip"
  }
}

################################################################
##                                                            ##
##  Outputs from the Frontend Build Process                   ##
##                                                            ##
################################################################

output "backend_code_bucket" {
  value       = data.external.backend_package.result.bucket
  description = "Name of the S3 bucket containing the backend code"
}

output "backend_code_key" {
  value       = data.external.backend_package.result.s3_key
  description = "S3 key of the uploaded backend code package"
}

output "backend_code_version" {
  value       = data.external.backend_package.result.version_id
  description = "Version ID of the uploaded backend code package"
}

output "backend_status" {
  value       = data.external.backend_package.result.status
  description = "Status of the backend packaging and upload process"
}

output "backend_message" {
  value       = data.external.backend_package.result.message
  description = "Detailed message about the backend packaging process"
}
