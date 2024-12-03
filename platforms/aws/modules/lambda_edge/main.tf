
resource "aws_iam_role" "lambda_execution_role" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_secrets_manager_policy" {
  name = "${var.environment}-${var.project_name}-secrets-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Effect   = "Allow"
        Resource = var.secret_arn
      }
    ]
  })
}


# CloudWatch Log Group for Lambda@Edge
resource "aws_cloudwatch_log_group" "lambda_edge_logs" {
  name = "/aws/lambda/${var.function_name}"
  tags = var.default_tags
}
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./lambda_code/"  # Path to your Lambda code directory
  output_path = "./lambda_code/lambda_function.zip"  # Path to save the generated zip file
}
resource "aws_lambda_function" "edge_function" {
  provider = aws.us-east-1

  function_name = var.function_name
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  #s3_bucket     = var.s3_bucket_name_edge
  #s3_key        = "lambda_function.zip"
  publish       = true
  memory_size   = 128
  filename = data.archive_file.lambda_zip.output_path
  ephemeral_storage {
    size = 512
  }


  depends_on = [aws_iam_role.lambda_execution_role]
}
