output "lambda_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.timetracking_auth_function.arn
}
output "lambda_published_version_arn" {
  description = "The ARN of the published Lambda function version"
  value       = aws_lambda_function.timetracking_auth_function.qualified_arn
}
