#output "secret_values" {
#  value = jsondecode(aws_secretsmanager_secret_version.secret_version.secret_string)
#}
output "secret_arn" {
  description = "The ARN of the secret"
  value       = aws_secretsmanager_secret.secret.arn
}
