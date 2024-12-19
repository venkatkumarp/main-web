#!/bin/bash

# Disable debug mode and exit on error
set -e

# Read JSON input from stdin (this is what Terraform passes)
eval "$(jq -r '@sh "
LAMBDA_FUNCTION_NAME=\(.lambda_function_name)
ECR_REPO_NAME=\(.ecr_repo_name)
ENVIRONMENT=\(.environment)
ECR_REGISTRY=\(.ecr_registry)
IMAGE_TAG=\(.image_tag)
REGION=\(.region)
"')"

# Log variables (to stderr)
>&2 echo "Environment: $ENVIRONMENT"
>&2 echo "Lambda Function: $LAMBDA_FUNCTION_NAME"
>&2 echo "ECR Repo: $ECR_REPO_NAME"
>&2 echo "ECR Registry: $ECR_REGISTRY"
>&2 echo "Image Tag: $IMAGE_TAG"
>&2 echo "Region: $REGION"

# Check if all required variables are present
if [ -z "$LAMBDA_FUNCTION_NAME" ] || [ -z "$ECR_REPO_NAME" ] || [ -z "$ECR_REGISTRY" ] || [ -z "$IMAGE_TAG" ] || [ -z "$REGION" ]; then
    # Output error as JSON to stdout
    jq -n \
        --arg error "Missing required variables" \
        '{"error": $error}'
    exit 1
fi

# Execute AWS commands (output to stderr)
{
    # Login to ECR
    >&2 echo "Logging into ECR..."
    aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

    # Build Docker image
    >&2 echo "Building Docker image..."
    docker build -t "$ECR_REGISTRY/$ECR_REPO_NAME:$IMAGE_TAG" .

    # Push to ECR
    >&2 echo "Pushing to ECR..."
    docker push "$ECR_REGISTRY/$ECR_REPO_NAME:$IMAGE_TAG"

    # Update Lambda
    >&2 echo "Updating Lambda function..."
    aws lambda update-function-code \
        --function-name "$LAMBDA_FUNCTION_NAME" \
        --image-uri "$ECR_REGISTRY/$ECR_REPO_NAME:$IMAGE_TAG" \
        --region "$REGION"
} || {
    # If any command fails, output error as JSON
    jq -n \
        --arg error "Failed to execute AWS commands" \
        '{"error": $error}'
    exit 1
}

# Output success as JSON to stdout
jq -n \
    --arg status "success" \
    --arg function "$LAMBDA_FUNCTION_NAME" \
    --arg tag "$IMAGE_TAG" \
    --arg region "$REGION" \
    '{
        status: $status,
        lambda_function: $function,
        image_tag: $tag,
        region: $region
    }'
