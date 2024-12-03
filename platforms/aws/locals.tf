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


  # Use existing WAF Web ACL name, adjust based on environment
  existing_web_acl_name = lookup({
    "440744244651" = "test-webacl"

  }, var.aws_account_id, null)


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

  # Secret values for timetracking-web
  secrets_manager = lookup({
    "440744244651" = {
      clientId              = "6a0de96b-1426-4351-805f-4cab20da188f"
      clientSecret          = "VsE8Q~-C-IfgJ-GcbkSLhYepnmFSpXaDG9rn3a1s"
      code_verifier         = "R4eU5uRSNK4_H5Mb7Ezw5NpTedV1Jo3S5WDTafLEjH4"
      tenantId              = "fcb2b37b-5da0-466b-9b83-0014b67a7c78"
      code_challenge        = "Z0IsUYreHoIRNTWBj0owlsVlOAiBHCNlfhrYKsnzmdU"
      code_challenge_method = "S256"
      redirectUri           = "https://ht2xz51fgk.execute-api.eu-central-1.amazonaws.com/np/test?Auth=123"
    }
  }, var.aws_account_id, null)

  # Dynamically set the S3 bucket name based on account ID
  s3_bucket_name = lookup({
    "440744244651" = "web.${local.environment}.times-tracking.int.venkat.com"

  }, var.aws_account_id, null)
  # Bucket for Lambda@Edge (us-east-1)
#  s3_bucket_name_edge = lookup({
#    "440744244651" = "web.${local.environment}.times-tracking.int.venkat.com"
#    "123456789012" = "my-bucket-prod-edge"
#  }, var.aws_account_id, null)
}

