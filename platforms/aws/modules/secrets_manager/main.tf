resource "aws_secretsmanager_secret" "this" {
  for_each    = var.secrets
  name        = each.key
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each     = var.secrets
  secret_id    = aws_secretsmanager_secret.this[each.key].id
  secret_string = jsonencode(each.value.secret_values)
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
