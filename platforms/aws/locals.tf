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

  vpc_cidrs = {
    "440744244651" = "10.149.176.0/25"
  }

  vpc_cidr = lookup(local.vpc_cidrs, var.aws_account_id, {})

  aws_region = "eu-central-1"

  aws_infra_deploy_role = "arn:aws:iam::${var.aws_account_id}:role/infra-dev-deploy-role"


  network_config = {
    "440744244651" = {
      availability_zones         = ["eu-central-1a", "eu-central-1b"]
      vpc_id                     = "vpc-0371a6b277250e394"
      subnet_public1             = "subnet-0ab465c2831bb4641"
      subnet_public2             = "subnet-08fe108379cbe5af0"
      subnet_private1            = "subnet-0ec5e4d2b3ff1532c"
      subnet_private2            = "subnet-055bc92e377ff501c"
      security_group_default_vpc = "sg-05cc1a350c5828355"

    }
  }

}
