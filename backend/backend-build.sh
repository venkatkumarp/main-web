#!/bin/bash
set -euo pipefail

# Check for required commands
command -v jq >/dev/null 2>&1 || { echo '{"error": "jq is not installed"}' >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo '{"error": "AWS CLI is not installed"}' >&2; exit 1; }


# Load JSON input using  jq
input_data=$(cat)
env=$(echo "$input_data" | jq -r '.environment // empty')
bucket_name=$(echo "$input_data" | jq -r '.bucket_name // empty')
output_path=$(echo "$input_data" | jq -r '.output_path // empty')

# Function for error handling that outputs valid JSON
error_exit() {
    # Ensure the error message is properly escaped for JSON
    escaped_error=$(echo "$1" | jq -R .)
    echo "{\"status\": \"error\", \"message\": ${escaped_error}}" >&2
    exit 1
}

# Check for required input variables
if [ -z "$env" ]; then
    error_exit "environment variable is not set in the input data."
fi

if [ -z "$bucket_name" ]; then
    error_exit "bucket_name variable is not set in the input data."
fi

if [ -z "$output_path" ]; then
    error_exit "output_path variable is not set in the input data."
fi

# Create temporary directory
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

# Get the directory where the script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for Python files
py_files=($(find "$script_dir" -maxdepth 1 -name "*.py"))
if [ ${#py_files[@]} -eq 0 ]; then
    error_exit "No Python files found in the current directory"
fi

# Copy Python files to temp directory
echo "Copying Python files..." >&2
cp "${py_files[@]}" "$temp_dir/" || error_exit "Failed to copy Python files"

# Create ZIP file
cd "$temp_dir" || error_exit "Failed to change to temporary directory"
if ! zip -r "$output_path" . -x "__pycache__/*" "*.pyc" >&2; then
    error_exit "Failed to create ZIP file"
fi

# Upload to S3 as backend.zip
if aws s3 cp "$output_path" "s3://$bucket_name/backend.zip" \
    --metadata "environment=$env" >&2; then
    echo "Successfully uploaded backend package to S3 as backend.zip" >&2
else
    error_exit "Failed to upload backend package to S3"
fi

# Retrieve version ID of uploaded object
version_id=$(aws s3api head-object \
    --bucket "$bucket_name" \
    --key "backend.zip" \
    --query 'VersionId' \
    --output text 2>/dev/null) || error_exit "Failed to get version ID"

# Get list of packaged Python files
packaged_files=($(find . -name "*.py" -printf "%P\n"))
packaged_files_string=$(printf '%s,' "${packaged_files[@]}" | sed 's/,$//')

# Output final JSON result
echo "{
    \"status\": \"success\",
    \"message\": \"Backend package created and uploaded to S3\",
    \"environment\": \"$env\",
    \"bucket\": \"$bucket_name\",
    \"version_id\": \"$version_id\",
    \"s3_key\": \"backend.zip\",
    \"packaged_count\": \"${#packaged_files[@]}\",
    \"packaged_files\": \"$packaged_files_string\"
}"
