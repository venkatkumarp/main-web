#!/bin/bash
set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo '{"error": "jq is not installed"}' >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo '{"error": "AWS CLI is not installed"}' >&2; exit 1; }

input_data=$(cat)
env=$(echo "$input_data" | jq -r '.ENVIRONMENT // empty')
bucket_name=$(echo "$input_data" | jq -r '.S3_BUCKET_NAME // empty')

error_exit() {
    escaped_error=$(echo "$1" | jq -R .)
    echo "{\"status\": \"error\", \"message\": ${escaped_error}}" >&2
    exit 1
}

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

if [ -z "$bucket_name" ]; then
    error_exit "S3_BUCKET_NAME variable is not set in the input data."
fi

npm install >&2 || error_exit "npm install failed"
npm run "build:$env" >&2 || error_exit "npm build failed"

dist_folder="dist/time-tracking-app"

if [ ! -d "$dist_folder" ]; then
    error_exit "Build directory $dist_folder not found. Build failed."
fi

cd "$dist_folder" || error_exit "Failed to change to $dist_folder directory"

if aws s3 cp "." "s3://$bucket_name" --recursive >&2; then
    echo "Successfully uploaded files to S3" >&2
else
    error_exit "Failed to upload files to S3"
fi

uploaded_files=($(find . -type f -printf "%P\n"))
uploaded_files_string=$(printf '%s,' "${uploaded_files[@]}" | sed 's/,$//') 

echo "{
    \"status\": \"success\",
    \"message\": \"Frontend build completed and files uploaded to S3\",
    \"environment\": \"$env\",
    \"bucket\": \"$bucket_name\",
    \"uploaded_count\": \"${#uploaded_files[@]}\",
    \"uploaded_files\": \"$uploaded_files_string\"
}"
