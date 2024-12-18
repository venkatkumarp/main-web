#!/bin/bash
set -euo pipefail

# Variables
image_name="backend-image"
aws_region="eu-central-1"
aws_account_id=$1
environment=$2
lambda_function_name="docker-lambda"

# Check for required commands
command -v docker >/dev/null 2>&1 || { echo "Docker is not installed"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "AWS CLI is not installed"; exit 1; }

# Log into AWS ECR
aws ecr get-login-password --region "$aws_region" | docker login --username AWS --password-stdin "${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com"

# Build the Docker image
docker build -t "${image_name}:${environment}" .

# Tag the image for ECR
ecr_repo="${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com/${image_name}"
docker tag "${image_name}:${environment}" "${ecr_repo}:${environment}"

# Push the image to ECR
docker push "${ecr_repo}:${environment}"

# Deploy the image to AWS Lambda
aws lambda update-function-code \
    --function-name "$lambda_function_name" \
    --image-uri "${ecr_repo}:${environment}" \
    --region "$aws_region"

echo "Docker image pushed to ECR and deployed to Lambda: ${lambda_function_name}"
