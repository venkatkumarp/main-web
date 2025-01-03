#!/bin/bash
set -euo pipefail

# Check for required commands
command -v jq >/dev/null 2>&1 || { echo '{"error": "jq is not installed"}' >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo '{"error": "AWS CLI is not installed"}' >&2; exit 1; }

# Load JSON input using jq
input_data=$(cat)
env=$(echo "$input_data" | jq -r '.ENVIRONMENT // empty')
bucket_name=$(echo "$input_data" | jq -r '.S3_BUCKET_NAME // empty')

# Function for error handling that outputs valid JSON
error_exit() {
    # Ensure the error message is properly escaped for JSON
    escaped_error=$(echo "$1" | jq -R .)
    echo "{\"status\": \"error\", \"message\": ${escaped_error}}" >&2
    exit 1
}

# Check for ENVIRONMENT variable
if [ -z "${ENVIRONMENT:-}" ]; then
    if [ -z "$env" ]; then
        error_exit "ENVIRONMENT variable is not set in the input data."
    else
        echo "Using ENVIRONMENT from input data: $env" >&2
    fi
else
    env="$ENVIRONMENT"
    echo "Using ENVIRONMENT from environment variable: $env" >&2
fi

# Check for S3 bucket name
if [ -z "$bucket_name" ]; then
    error_exit "S3_BUCKET_NAME variable is not set in the input data."
fi

# Ensure frontend build
npm install >&2 || error_exit "npm install failed"
npm run "build:$env" >&2 || error_exit "npm build failed"

# Define the specific build output path
build_path="dist/time-tracking-app"

# Check if the specific build path exists
if [ ! -d "$build_path" ]; then
    error_exit "Build directory $build_path not found. Build failed."
fi

# Create a temporary directory for the files
temp_dir=$(mktemp -d)

# Copy contents of time-tracking-app directory to temp directory
cp -r "$build_path"/* "$temp_dir/" || error_exit "Failed to copy build files to temporary directory"

# Upload the contents to S3 recursively
if aws s3 cp "$temp_dir" "s3://$bucket_name" --recursive >&2; then
    echo "Successfully uploaded $build_path contents to S3" >&2
else
    error_exit "Failed to upload $build_path contents to S3"
fi

# Clean up temporary directory
rm -rf "$temp_dir"

# Get list of uploaded files
uploaded_files=($(find "$build_path" -type f -printf "%P\n"))
uploaded_files_string=$(printf '%s,' "${uploaded_files[@]}" | sed 's/,$//')

# Output final JSON result
echo "{
    \"status\": \"success\",
    \"message\": \"Frontend build completed and files uploaded to S3\",
    \"environment\": \"$env\",
    \"bucket\": \"$bucket_name\",
    \"uploaded_count\": \"${#uploaded_files[@]}\",
    \"uploaded_files\": \"$uploaded_files_string\"
}"
