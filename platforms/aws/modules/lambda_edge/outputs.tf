output "lambda_edge_arn" {
  value = aws_lambda_function.edge_function.arn
}

output "lambda_edge_version_arn" {
  value = aws_lambda_function.edge_function.arn
}

output "lambda_qualified_arn" {
  value = aws_lambda_function.edge_function.qualified_arn
}

