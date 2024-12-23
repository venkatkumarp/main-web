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

# Store initial directory
initial_dir=$(pwd)

npm install >&2 || error_exit "npm install failed"
npm run "build:$env" >&2 || error_exit "npm build failed"

dist_folder="dist/time-tracking-app"
if [ ! -d "$dist_folder" ]; then
    error_exit "Build directory $dist_folder not found. Build failed."
fi

# Check for essential files before upload
essential_files=("index.html" "assets")
for file in "${essential_files[@]}"; do
    if [ ! -e "$dist_folder/$file" ]; then
        error_exit "Essential file/directory missing: $file"
    fi
done

cd "$dist_folder" || error_exit "Failed to change to $dist_folder directory"

# List files before upload
echo "Files to upload:" >&2
ls -la >&2

# Upload with sync instead of cp to ensure all files are transferred
if aws s3 sync "." "s3://$bucket_name" --delete >&2; then
    echo "Successfully uploaded files to S3" >&2
else
    cd "$initial_dir"
    error_exit "Failed to upload files to S3"
fi

# Verify upload by listing bucket contents
echo "Verifying uploaded files:" >&2
aws s3 ls "s3://$bucket_name" --recursive >&2

# Create file list
uploaded_files=($(find . -type f -printf "%P\n"))
if [ ${#uploaded_files[@]} -eq 0 ]; then
    cd "$initial_dir"
    error_exit "No files found for upload"
fi

uploaded_files_string=$(printf '%s,' "${uploaded_files[@]}" | sed 's/,$//') 

# Return to initial directory
cd "$initial_dir"

echo "{
    \"status\": \"success\",
    \"message\": \"Frontend build completed and files uploaded to S3\",
    \"environment\": \"$env\",
    \"bucket\": \"$bucket_name\",
    \"uploaded_count\": \"${#uploaded_files[@]}\",
    \"uploaded_files\": \"$uploaded_files_string\"
}"
