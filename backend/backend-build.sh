#!/bin/bash
#set -euo pipefail

# Function for logging to stderr (won't affect JSON output)
log() {
    echo "$1" >&2
}

# Check required tools
command -v jq >/dev/null 2>&1 || { log "jq is not installed"; exit 1; }
command -v docker >/dev/null 2>&1 || { log "Docker is not installed"; exit 1; }
command -v aws >/dev/null 2>&1 || { log "AWS CLI is not installed"; exit 1; }

# Read input
input_data=$(cat)
lambda_function_name=$(echo "$input_data" | jq -r '.lambda_function_name // empty')
ecr_repo_name=$(echo "$input_data" | jq -r '.ecr_repo_name // empty')
environment=$(echo "$input_data" | jq -r '.environment // empty')
ecr_registry=$(echo "$input_data" | jq -r '.ecr_registry // empty')
image_tag=$(echo "$input_data" | jq -r '.image_tag // empty')
aws_region=$(echo "$input_data" | jq -r '.region // empty')

# Validate required parameters
if [[ -z "$lambda_function_name" || -z "$ecr_repo_name" || -z "$ecr_registry" || -z "$image_tag" || -z "$aws_region" ]]; then
    log "Error: Missing required parameters"
    log "Required: lambda_function_name, ecr_repo_name, ecr_registry, image_tag, aws_region"
    exit 1
fi

log "Starting build process for $lambda_function_name..."
log "Using ECR repository: $ecr_repo_name"

# Login to ECR
if ! aws ecr get-login-password --region "$aws_region" | docker login --username AWS --password-stdin "$ecr_registry" >&2; then
    log "Error: Failed to login to ECR"
    exit 1
fi

# Build and push image
if ! timeout 300 docker build -t "$ecr_registry/$ecr_repo_name:$image_tag" . >&2; then
    log "Error: Docker build failed"
    exit 1
fi

if ! docker push "$ecr_registry/$ecr_repo_name:$image_tag" >&2; then
    log "Error: Docker push failed"
    exit 1
fi

# Update Lambda function
if ! aws lambda update-function-code \
    --function-name "$lambda_function_name" \
    --image-uri "$ecr_registry/$ecr_repo_name:$image_tag" \
    --region "$aws_region" >&2; then
    log "Error: Failed to update Lambda function"
    exit 1
fi

# Output only the JSON result to stdout
jq -n \
  --arg lambda_function "$lambda_function_name" \
  --arg ecr_repo "$ecr_repo_name" \
  --arg environment "$environment" \
  --arg ecr_registry "$ecr_registry" \
  --arg image_tag "$image_tag" \
  --arg aws_region "$aws_region" \
  '{
    lambda_function: $lambda_function,
    ecr_repo: $ecr_repo,
    environment: $environment,
    ecr_registry: $ecr_registry,
    image_tag: $image_tag,
    aws_region: $aws_region
  }'
