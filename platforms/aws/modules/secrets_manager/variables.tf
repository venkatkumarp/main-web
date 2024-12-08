/*variable "secret_name" {}
variable "client_secret" {}
variable "code_verifier" {}
variable "code_challenge" {}*/

variable "aws_account_id" {}

variable "project_name" {
  description = "Project name for S3 bucket"
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

####
variable "secret_values" {
  description = "Key-value pairs for secret data"
  type        = map(string)
}
variable "secret_name" {
  description = "The name of the secret"
  type        = string
}
