variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "lambda_arn" {
  description = "Lambda ARN for the authorizer"
  type        = string
}
variable "api_gateway_name" {
  description = "The name of the API Gateway"
  type        = string
}

variable "api_gateway_authorizer_name" {
  description = "The name of the API Gateway authorizer"
  type        = string
}

variable "api_gateway_stage_name" {
  description = "The name of the API Gateway stage"
  type        = string
}
