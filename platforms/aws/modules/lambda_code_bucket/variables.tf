variable "aws_account_id" {}

variable "project_name" {
  description = "Project name for S3 bucket"
  type        = string
}
variable "lambda_bucket_name" {
  description = "The name of the S3 bucket to create"
  type        = string
}
variable "default_tags" {
  description = "Default tags for resources"
  type        = map(string)
}

variable "environment" {
  description = "Environment for the deployment (dev, QA, prod)"
  type        = string
}