#!/bin/bash
set -euo pipefail

# Debugging output to show script progress
echo "Starting backend-build.sh"

# Check if necessary commands are installed
command -v jq >/dev/null 2>&1 || { echo "jq is not installed"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Docker is not installed"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "AWS CLI is not installed"; exit 1; }

# Read input data from Terraform query
echo "Reading input data from Terraform"
read input_data
lambda_function_name=$(echo "$input_data" | jq -r '.lambda_function_name')
ecr_repo_name=$(echo "$input_data" | jq -r '.ecr_repo_name')
environment=$(echo "$input_data" | jq -r '.environment')
ecr_registry=$(echo "$input_data" | jq -r '.ecr_registry')
image_tag=$(echo "$input_data" | jq -r '.image_tag')
aws_region=$(echo "$input_data" | jq -r '.region')

# Print values of the inputs to check if they are correctly parsed
echo "lambda_function_name: $lambda_function_name"
echo "ecr_repo_name: $ecr_repo_name"
echo "environment: $environment"
echo "ecr_registry: $ecr_registry"
echo "image_tag: $image_tag"
echo "aws_region: $aws_region"

# Check for missing values and fail gracefully
[[ -z "$lambda_function_name" ]] && echo "Error: lambda_function_name is empty" && exit 1
[[ -z "$ecr_repo_name" ]] && echo "Error: ecr_repo_name is empty" && exit 1
[[ -z "$ecr_registry" ]] && echo "Error: ecr_registry is empty" && exit 1
[[ -z "$image_tag" ]] && echo "Error: image_tag is empty" && exit 1
[[ -z "$aws_region" ]] && echo "Error: aws_region is empty" && exit 1

# Build the Docker image with the tag provided
echo "Building Docker image: $ecr_registry/$ecr_repo_name:$image_tag"
docker build -t "$ecr_registry/$ecr_repo_name:$image_tag" .

# Push the image to ECR
echo "Pushing Docker image to ECR"
docker push "$ecr_registry/$ecr_repo_name:$image_tag"

# Deploy the image to AWS Lambda
echo "Updating Lambda function with new image"
aws lambda update-function-code \
    --function-name "$lambda_function_name" \
    --image-uri "$ecr_registry/$ecr_repo_name:$image_tag" \
    --region "$aws_region"

# Final success message
echo "Deployment successful!"

# Return status to Terraform
echo "{\"status\": \"success\", \"lambda_function\": \"$lambda_function_name\", \"image_tag\": \"$image_tag\", \"region\": \"$aws_region\"}"
