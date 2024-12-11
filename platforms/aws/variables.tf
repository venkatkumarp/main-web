variable "aws_account_id" {
  type        = string
  description = "Account ID AWS"
}

variable "client_secret" {
  description = "Client secret for the environment"
  type        = string
}
variable "code_verifier" {
  description = "Code verifier for the environment"
  type        = string
}

variable "code_challenge" {
  description = "Code challenge for the environment"
  type        = string
}