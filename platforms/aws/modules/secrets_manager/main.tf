resource "aws_secretsmanager_secret" "this" {
  for_each    = var.secrets
  name        = each.key
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each     = var.secrets
  secret_id    = aws_secretsmanager_secret.this[each.key].id
  secret_string = jsonencode(each.value.secret_values)
}
variable "default_tags" {
  description = "Default tags for resources"
  type        = map(string)
}

variable "environment" {
  description = "Environment for the deployment"
  type        = string
}

variable "project_name" {
  description = "Project name for S3 bucket"
  type        = string
}
variable "secrets" {
  type        = map(object({
    secret_values = map(string)
    description   = string
  }))
}

output "secret_arn" {
  value = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}
output "secret_values" {
  value = { for k, v in aws_secretsmanager_secret_version.this : k => jsondecode(v.secret_string) }
}
