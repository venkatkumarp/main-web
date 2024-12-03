variable "default_tags" {
  description = "Default tags for resources"
  type        = map(string)
}

variable "environment" {
  description = "Environment for the deployment (dev, QA, prod)"
  type        = string
}
variable "secret_name" {
  description = "Name of the AWS Secrets Manager secret"
  type        = string
}

variable "secret_values" {
  description = "Map of secret key-value pairs to be stored in AWS Secrets Manager"
  type        = map(string)
}
