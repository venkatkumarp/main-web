variable "project_name" {
  description = "Project name for CloudFront"
  type        = string
}
variable "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket for CloudFront origin"
  type        = string
}

variable "default_tags" {
  description = "Default tags for resources"
  type        = map(string)
}

variable "existing_web_acl_name" {
  description = "Name of the existing Web ACL"
  type        = string
}

variable "environment" {
  description = "Environment for the deployment (dev, QA, prod)"
  type        = string
}
variable "lambda_edge_arn" {
  description = "ARN of the Lambda@Edge function"
  type        = string
}
variable "s3_bucket_name" {
  description = "The name of the S3 bucket to use as the CloudFront origin"
  type        = string
}
