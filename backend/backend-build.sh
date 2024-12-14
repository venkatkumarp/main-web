#!/bin/bash
set -euo pipefail
# Check for required commands
command -v jq >/dev/null 2>&1 || { echo '{"error": "jq is not installed"}' >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo '{"error": "AWS CLI is not installed"}' >&2; exit 1; }
# Load JSON input using jq
input_data=$(cat)
env=$(echo "$input_data" | jq -r '.environment // empty')
bucket_name=$(echo "$input_data" | jq -r '.bucket_name // empty')
output_path_layer=$(echo "$input_data" | jq -r '.output_path_layer // empty')
output_path_function=$(echo "$input_data" | jq -r '.output_path_function // empty')
# Function for error handling that outputs valid JSON
error_exit() {
    escaped_error=$(echo "$1" | jq -R .)
    echo "{\"error\": ${escaped_error}}" >&2
    exit 1
}
# Check for required input variables
if [ -z "$env" ]; then
    error_exit "environment variable is not set in the input data."
fi
if [ -z "$bucket_name" ]; then
    error_exit "bucket_name variable is not set in the input data."
fi
if [ -z "$output_path_layer" ]; then
    error_exit "output_path_layer variable is not set in the input data."
fi
if [ -z "$output_path_function" ]; then
    error_exit "output_path_function variable is not set in the input data."
fi
# Create temporary directory
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
# Get the directory where the script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Check for API and Backend folders
api_folder="$script_dir/api"
backend_folder="$(dirname "$script_dir")/backend"
if [ ! -d "$api_folder" ]; then
    error_exit "No 'api' folder found for Lambda layer"
fi
if [ ! -d "$backend_folder" ]; then
    error_exit "No 'backend' folder found for Lambda function"
fi
# Create temporary copies
cp -r "$api_folder" "$temp_dir/api"
cp -r "$backend_folder" "$temp_dir/backend"
# Create ZIP file for Lambda Layer (API folder)
cd "$temp_dir" || error_exit "Failed to change to temporary directory"
if ! zip -r "$output_path_layer" api >&2; then
    error_exit "Failed to create Lambda Layer ZIP file"
fi
# Create ZIP file for Lambda Function (Backend folder)
if ! zip -r "$output_path_function" backend >&2; then
    error_exit "Failed to create Lambda Function ZIP file"
fi
# Upload Lambda Layer to S3
if aws s3 cp "$output_path_layer" "s3://$bucket_name/tt_lambda_layer.zip" \
    --metadata "environment=$env" >&2; then
    echo "Successfully uploaded Lambda Layer package to S3 as tt_lambda_layer.zip" >&2
else
    error_exit "Failed to upload Lambda Layer package to S3"
fi
# Upload Lambda Function to S3
if aws s3 cp "$output_path_function" "s3://$bucket_name/tt_lambda_function.zip" \
    --metadata "environment=$env" >&2; then
    echo "Successfully uploaded Lambda Function package to S3 as tt_lambda_function.zip" >&2
else
    error_exit "Failed to upload Lambda Function package to S3"
fi
# Prepare JSON output for Terraform
echo "{
    \"bucket\": \"$bucket_name\",
    \"s3_key\": \"tt_lambda_function.zip\",
    \"version_id\": \"$(date +%s)\",
    \"status\": \"success\",
    \"message\": \"Lambda Layer and Function packages created and uploaded to S3\",
    \"layer_s3_key\": \"tt_lambda_layer.zip\",
    \"function_s3_key\": \"tt_lambda_function.zip\",
    \"environment\": \"$env\",
    \"layer_packaged_count\": \"$(find "$temp_dir/api" -type f | wc -l)\",
    \"function_packaged_count\": \"$(find "$temp_dir/backend" -type f | wc -l)\"
}"
