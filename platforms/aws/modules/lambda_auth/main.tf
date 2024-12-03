
resource "aws_iam_role" "lambda_execution_role" {
  name = var.lambda_auth_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "${var.project_name}-secrets-manager-policy"
  description = "Policy to allow access to AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_manager_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_auth_logs" {
  name = "/aws/lambda/${var.lambda_auth_function_name}"
  tags = var.default_tags
}


resource "aws_lambda_function" "timetracking_auth_function" {
  function_name = var.lambda_auth_function_name
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  s3_bucket     = var.s3_bucket_name
  s3_key        = "lambda_function.zip"
  publish       = true
  memory_size   = 2048
  ephemeral_storage {
    size = 512
  }

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}
