# AWS providers
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
    Repository  = "https://github.com/"
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

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  assume_role {
    role_arn = local.aws_infra_deploy_role
  }
}

