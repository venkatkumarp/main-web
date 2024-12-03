variable "project_name" {
  description = "The project name"
  type        = string
}

variable "environment" {
  description = "The environment (dev, prod, etc.)"
  type        = string
}

variable "default_tags" {
  description = "Default tags to be applied"
  type        = map(string)
}
variable "gettoken_lambda_role_name" {
  description = "The name of the Lambda execution role"
  type        = string
}

variable "gettoken_lambda_function_name" {
  description = "The name of the Lambda function"
  type        = string
}

variable "secret_manager" {
  description = "ARN of the Secrets Manager secret"
  type        = string
}
variable "s3_bucket_name" {
  description = "The S3 bucket name to use for downloading the Lambda code"
  type        = string
}
