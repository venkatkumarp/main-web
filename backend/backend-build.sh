#!/bin/bash
set -euo pipefail
set -x  # Enable debugging output (disable this if it causes non-JSON output)

# Function to output a JSON error and exit
function json_error {
  echo "{\"status\": \"error\", \"message\": \"$1\"}"
  exit 1
}

# Check if necessary commands are installed
command -v jq >/dev/null 2>&1 || json_error "jq is not installed"
command -v docker >/dev/null 2>&1 || json_error "Docker is not installed"
command -v aws >/dev/null 2>&1 || json_error "AWS CLI is not installed"

# Read input data from Terraform query directly using jq
input_data=$(cat)

lambda_function_name=$(echo "$input_data" | jq -r '.lambda_function_name')
ecr_repo_name=$(echo "$input_data" | jq -r '.ecr_repo_name')
environment=$(echo "$input_data" | jq -r '.environment')
ecr_registry=$(echo "$input_data" | jq -r '.ecr_registry')
image_tag=$(echo "$input_data" | jq -r '.image_tag')
aws_region=$(echo "$input_data" | jq -r '.region')

# Check for missing values and fail gracefully
[[ -z "$lambda_function_name" ]] && json_error "lambda_function_name is empty"
[[ -z "$ecr_repo_name" ]] && json_error "ecr_repo_name is empty"
[[ -z "$ecr_registry" ]] && json_error "ecr_registry is empty"
[[ -z "$image_tag" ]] && json_error "image_tag is empty"
[[ -z "$aws_region" ]] && json_error "aws_region is empty"

# Authenticate Docker with AWS ECR
aws ecr get-login-password --region "$aws_region" | docker login --username AWS --password-stdin "$ecr_registry" || json_error "Failed to authenticate Docker with AWS ECR"

# Build the Docker image
docker build -t "$ecr_registry/$ecr_repo_name:$image_tag" . || json_error "Docker build failed"

# Push the Docker image to ECR
docker push "$ecr_registry/$ecr_repo_name:$image_tag" || json_error "Docker push failed"

# Deploy the image to AWS Lambda
aws lambda update-function-code \
    --function-name "$lambda_function_name" \
    --image-uri "$ecr_registry/$ecr_repo_name:$image_tag" \
    --region "$aws_region" || json_error "Lambda function update failed"

# Final success message, return in JSON format
echo "{\"status\": \"success\", \"message\": \"Deployment successful!\", \"image_uri\": \"$ecr_registry/$ecr_repo_name:$image_tag\", \"region\": \"$aws_region\"}"
