data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./modules/cloudfront/point-handler"
  output_path = "./modules/cloudfront/point-handler-${var.commit_id}.zip"
}

resource "aws_iam_role" "gettoken_lambda_role" {
  name = var.gettoken_lambda_role_name
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


resource "aws_iam_role_policy_attachment" "gettoken_lambda_policy_attachment" {
  role       = aws_iam_role.gettoken_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_secrets_manager_policy" {
  name = "${var.environment}-${var.project_name}-secrets-policy"
  role = aws_iam_role.gettoken_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name = "/aws/lambda/${var.gettoken_lambda_function_name}"
  tags = var.default_tags
}

resource "aws_lambda_function" "gettoken_lambda_function" {
  function_name = var.gettoken_lambda_function_name
  runtime       = "python3.12"
  role          = aws_iam_role.gettoken_lambda_role.arn
  handler       = "point-handler.point_handler"
  filename      = data.archive_file.lambda_zip.output_path
  #s3_bucket     = var.s3_bucket_name
  #s3_key        = "lambda_function.zip"
  publish       = true
  memory_size   = 1024
  ephemeral_storage {
    size = 512
  }

  environment {
    variables = {
      ENVIRONMENT = var.environment
      CLIENT_ID       = var.clientID
      CDN_URL         = var.cdnurl
      TENANT_ID       = var.tenantId
      REDIRECT_URI    = var.redirectUri
      CLIENT_SECRET   = var.client_secret
      CODE_VERIFIER   = var.code_verifier
      CODE_CHALLENGE  = var.code_challenge
      CODE_CHALLENGE_METHOD = var.code_challenge_method
    }
  }
}

