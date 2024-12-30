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


variable "secret_values" {
  description = "Key-value pairs for secret data"
  type        = map(string)
}
variable "secret_name" {
  description = "The name of the secret"
  type        = string
}


variable "clientID" {
description = "cleint ID"
type = string
}
variable "tenantId" {
  description = "Tenant ID for the secret"
  type        = string
}

variable "redirectUri" {
  description = "Redirect URI for the secret"
  type        = string
}
variable "cdnurl" {
  description = "cloudfront url"
  type        = string
}

variable "code_challenge_method" {
  description = "code challenge method value"
  type        = string
}

variable "db_server" {}
variable "db_name" {}
variable "db_user" {}

variable "journyx_url" {}
variable "journyx_user" {}
