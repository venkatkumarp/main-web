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
variable "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  type        = string
}
variable "lambda_auth_role_name" {
  description = "The name of the Lambda execution role"
  type        = string
}

variable "lambda_auth_function_name" {
  description = "The name of the Lambda function"
  type        = string
}
variable "s3_bucket_name" {
  description = "The name of the S3 bucket for the Lambda zip file"
  type        = string
}
