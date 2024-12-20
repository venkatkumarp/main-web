#!/bin/bash
set -euo pipefail

# Function for logging to stderr
log() {
    echo "$1" >&2
}

# Check required tools
command -v jq >/dev/null 2>&1 || { log "jq is not installed"; exit 1; }
command -v aws >/dev/null 2>&1 || { log "AWS CLI is not installed"; exit 1; }

# Read input
input_data=$(cat)
lambda_function_name=$(echo "$input_data" | jq -r '.lambda_function_name // empty')
ecr_repo_name=$(echo "$input_data" | jq -r '.ecr_repo_name // empty')
environment=$(echo "$input_data" | jq -r '.environment // empty')
ecr_registry=$(echo "$input_data" | jq -r '.ecr_registry // empty')
image_tag=$(echo "$input_data" | jq -r '.image_tag // empty')
aws_region=$(echo "$input_data" | jq -r '.region // empty')
mode=$(echo "$input_data" | jq -r '.mode // "read"')

# Validate required parameters
if [[ -z "$lambda_function_name" || -z "$ecr_repo_name" || -z "$ecr_registry" || -z "$image_tag" || -z "$aws_region" ]]; then
    log "Error: Missing required parameters"
    log "Required: lambda_function_name, ecr_repo_name, ecr_registry, image_tag, aws_region"
    exit 1
fi

# Initialize variables
current_image=""
version_tag="$image_tag"
latest_tag="${image_tag}-latest"

# Get current Lambda configuration
log "Checking current Lambda configuration..."
current_config=$(aws lambda get-function \
    --function-name "$lambda_function_name" \
    --region "$aws_region" 2>/dev/null || echo '{}')
current_image=$(echo "$current_config" | jq -r '.Configuration.PackageType // "Image"')

# Only proceed with deployment in apply mode
if [[ "$mode" == "apply" ]]; then
    log "Running in apply mode - starting deployment process..."
    command -v docker >/dev/null 2>&1 || { log "Docker is not installed"; exit 1; }

    # Generate git hash if available
    git_hash=""
    if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git_hash="-$(git rev-parse --short HEAD)"
    fi

    # Update version tag with git hash (no timestamp)
    version_tag="${image_tag}${git_hash}"
    latest_tag="${image_tag}-latest"

    log "Starting build process for $lambda_function_name..."
    log "Using ECR repository: $ecr_repo_name"
    log "Version tag: $version_tag"

    # Login to ECR
    if ! aws ecr get-login-password --region "$aws_region" | docker login --username AWS --password-stdin "$ecr_registry" >&2; then
        log "Error: Failed to login to ECR"
        exit 1
    fi

    # Build image with error handling
    if ! timeout 300 docker build -t "$ecr_registry/$ecr_repo_name:$version_tag" \
                                -t "$ecr_registry/$ecr_repo_name:$latest_tag" . >&2; then
        log "Error: Docker build failed. Please check your Dockerfile and build context."
        exit 1
    fi

    # Push version tag with error handling
    if ! docker push "$ecr_registry/$ecr_repo_name:$version_tag" >&2; then
        log "Error: Failed to push version tag. Please check ECR permissions and network connectivity."
        exit 1
    fi

    # Push latest tag with error handling
    if ! docker push "$ecr_registry/$ecr_repo_name:$latest_tag" >&2; then
        log "Error: Failed to push latest tag. Please check ECR permissions and network connectivity."
        exit 1
    fi

    # Clean up old images (keep last 5 versions) with better error handling
    if ! aws ecr list-images \
        --repository-name "$ecr_repo_name" \
        --region "$aws_region" \
        --filter "tagStatus=TAGGED" \
        --query 'imageIds[?contains(imageTag, `'"${image_tag}"'`)]' \
        --output json | \
        jq -r '[.[] | select(.imageTag != "'"${latest_tag}"'") | .imageTag] | sort | .[:-5] | .[]' | \
        while read -r old_tag; do
            log "Removing old image tag: $old_tag"
            aws ecr batch-delete-image \
                --repository-name "$ecr_repo_name" \
                --region "$aws_region" \
                --image-ids imageTag="$old_tag" >&2 || \
                log "Warning: Failed to delete image tag: $old_tag"
        done; then
        log "Warning: Image cleanup process encountered issues"
    fi

    # Update Lambda function with improved error handling
    if ! aws lambda update-function-code \
        --function-name "$lambda_function_name" \
        --image-uri "$ecr_registry/$ecr_repo_name:$version_tag" \
        --region "$aws_region" >&2; then
        log "Error: Failed to update Lambda function. Please check Lambda permissions and configuration."
        exit 1
    fi
else
    log "Running in read/plan mode - skipping deployment..."
fi

# Output JSON result
jq -n \
  --arg lambda_function "$lambda_function_name" \
  --arg ecr_repo "$ecr_repo_name" \
  --arg environment "$environment" \
  --arg ecr_registry "$ecr_registry" \
  --arg image_tag "$version_tag" \
  --arg latest_tag "$latest_tag" \
  --arg aws_region "$aws_region" \
  --arg current_image "$current_image" \
  --arg mode "$mode" \
  '{
    lambda_function: $lambda_function,
    ecr_repo: $ecr_repo,
    environment: $environment,
    ecr_registry: $ecr_registry,
    image_tag: $image_tag,
    latest_tag: $latest_tag,
    aws_region: $aws_region,
    current_image: $current_image,
    mode: $mode
  }'
