variable "aws_account_id" {}
variable "project_name" {
  description = "Project name for S3 bucket"
  type        = string
}
variable "default_tags" {
  description = "Default tags for resources"
  type        = map(string)
}

variable "cloudfront_oac_id" { 
  description = "The ID of the CloudFront Origin Access Control"
  type        = string
}

variable "cloudfront_distribution_id" { 
  description = "The ID of the CloudFront distribution"
  type        = string
}

variable "environment" {
  description = "Environment for the deployment (dev, QA, prod)"
  type        = string
}
variable "permission_for_logs" {
  description = "Permission to store logs"
  type        = string
}
