#################
locals {

  project_name = "time-test"

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

  vpc_cidrs = {
    "440744244651" = "10.149.176.0/25"
    "423623838336" = "10.149.177.0/25"
  }

  vpc_cidr = lookup(local.vpc_cidrs, var.aws_account_id, {})

  aws_region = "eu-central-1"

  aws_infra_deploy_role = "arn:aws:iam::${var.aws_account_id}:role/infra-${local.environment}-deploy-roles"


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
  s3_bucket_name = lookup({
    "440744244651" = "web.dev.times-tracking.int.venkat.com"
  }, var.aws_account_id, null)

  # Web secrets configuration
  #secret_name     = "${local.environment}-client-secret"
    # Use lookup for secret name based on AWS account ID
# working part
  /*secret_name = lookup({
    "440744244651" = "${local.environment}-client-secret"
  }, var.aws_account_id, "null")*/ # working part
  secrets = lookup({
    "440744244651" = {
      clientID   = "clientid_need_to_Add"
      cdnurl    = "cdn_url_need_to"
      tenantId    = "this-is-tenantid"
      redirectUri = "this-is-redirect-uri-value"
      code_challenge_method = "addmethod"
      web_secrets = "/tt/${local.environment}/web-secrets6"
    }
  }, var.aws_account_id, null)

  # Dynamically construct the secret names based on environment
  #web_secrets = "/tt/${local.environment}/web-secrets5"
  cwid_db_secrets = "/tt/${local.environment}/cwid-db-secrets6"
  sap_hana_secrets = "/tt/${local.environment}/sap-secrets6"
  journyx_secrets = "/tt/${local.environment}/journyx-secrets6"
}
