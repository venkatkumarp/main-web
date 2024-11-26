data "archive_file" "lambda_zip" {
  type = "zip"
  source_dir = "../phd-web/lambda_code" # Path to the lambda function code directory
  output_path = "${path.module}/lambda_function.zip" # Path to output the zip file
}

resource "aws_lambda_function" "example_lambda" {
  function_name = "example-lambda"
  role = aws_iam_role.lambda_execution_role.arn # IAM role for Lambda execution
  handler = "index.handler" # Entry point to the Lambda function (index.js, handler function)
  runtime = "nodejs18.x" # Runtime environment for the Lambda function

  # Path to the zipped Lambda function file
  filename = data.archive_file.lambda_zip.output_path

  # Timeout and memory settings (optional)
  timeout = 15
  memory_size = 128

}


resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
        Sid = ""
      },
    ]
  })
}
