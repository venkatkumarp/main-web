resource "aws_apigatewayv2_api" "http_api" {
#  name          = "${var.project_name}-http-api-${var.environment}"
  name          = var.api_gateway_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_origins = ["*"] # Replace "*" with specific origins if needed for better security.
  }
}

resource "aws_apigatewayv2_authorizer" "lambda_authorizer" {
  #name         = "${var.project_name}-auth"
  name                   = var.api_gateway_authorizer_name
  api_id       = aws_apigatewayv2_api.http_api.id
  authorizer_type = "REQUEST"
  authorizer_uri  = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_arn}/invocations"
  identity_sources = ["$request.header.Authorization"]
  authorizer_payload_format_version = "2.0"
  enable_simple_responses      = true  # Additional optional configuration
}

# Integration with the Lambda Function

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_arn}/invocations"
}

/*resource "aws_apigatewayv2_route" "get_method" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /test"
  target     = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  authorization_type = "CUSTOM"
  authorizer_id = aws_apigatewayv2_authorizer.lambda_authorizer.id
}*/

# Route Definition with Wildcard Support (*)
resource "aws_apigatewayv2_route" "wildcard_route" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "ANY /{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.lambda_authorizer.id
}

# CORS Configuration
/*resource "aws_apigatewayv2_route_settings" "cors_configuration" {
  api_id     = aws_apigatewayv2_api.http_api.id
  stage_name = aws_apigatewayv2_stage.stage.name

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_origins = ["*"] # Replace "*" with specific origins if needed for better security.
  }
}*/

# Stage to deploy the API

resource "aws_apigatewayv2_stage" "stage" {
  api_id    = aws_apigatewayv2_api.http_api.id
 # name      = "test"
  name      = var.api_gateway_stage_name
  auto_deploy = true
}
