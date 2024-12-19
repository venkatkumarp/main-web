#!/bin/bash


# Redirect all output to stderr by default
exec 1>&2

# Enable strict mode
set -euo pipefail
set -x
# Function to output a JSON error to stdout
function json_error {
    >&1 echo "{\"error\": \"$1\", \"status\": \"error\"}"
    exit 1
}

# Function to output success JSON to stdout
function json_success {
    local image_uri="$1"
    >&1 echo "{\"status\": \"success\", \"message\": \"Deployment completed\", \"image_uri\": \"$image_uri\"}"
}

# Log function (writes to stderr)
function log {
    echo "[$(date -u)]: $*"
}

# Check if necessary commands are installed
command -v jq >/dev/null 2>&1 || json_error "jq is not installed"
command -v docker >/dev/null 2>&1 || json_error "Docker is not installed"
command -v aws >/dev/null 2>&1 || json_error "AWS CLI is not installed"

# Read input data from Terraform query
input_data=$(cat)
log "Reading input data from Terraform"

# Parse input with error handling
lambda_function_name=$(echo "$input_data" | jq -r '.lambda_function_name') || json_error "Failed to parse lambda_function_name"
ecr_repo_name=$(echo "$input_data" | jq -r '.ecr_repo_name') || json_error "Failed to parse ecr_repo_name"
environment=$(echo "$input_data" | jq -r '.environment') || json_error "Failed to parse environment"
ecr_registry=$(echo "$input_data" | jq -r '.ecr_registry') || json_error "Failed to parse ecr_registry"
image_tag=$(echo "$input_data" | jq -r '.image_tag') || json_error "Failed to parse image_tag"
aws_region=$(echo "$input_data" | jq -r '.region') || json_error "Failed to parse region"

# Validate inputs
[[ -z "$lambda_function_name" ]] && json_error "lambda_function_name is empty"
[[ -z "$ecr_repo_name" ]] && json_error "ecr_repo_name is empty"
[[ -z "$ecr_registry" ]] && json_error "ecr_registry is empty"
[[ -z "$image_tag" ]] && json_error "image_tag is empty"
[[ -z "$aws_region" ]] && json_error "aws_region is empty"

# Build and deploy
log "Authenticating with ECR..."
aws ecr get-login-password --region "$aws_region" | docker login --username AWS --password-stdin "$ecr_registry" || \
    json_error "ECR authentication failed"

log "Building Docker image..."
docker build -t "$ecr_registry/$ecr_repo_name:$image_tag" . || \
    json_error "Docker build failed"

log "Pushing to ECR..."
docker push "$ecr_registry/$ecr_repo_name:$image_tag" || \
    json_error "Failed to push to ECR"

log "Updating Lambda function..."
aws lambda update-function-code \
    --function-name "$lambda_function_name" \
    --image-uri "$ecr_registry/$ecr_repo_name:$image_tag" \
    --region "$aws_region" || \
    json_error "Failed to update Lambda function"

# Return success JSON to stdout
json_success "$ecr_registry/$ecr_repo_name:$image_tag"
