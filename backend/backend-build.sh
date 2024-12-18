#!/bin/bash
set -euo pipefail

# Check for required commands
command -v jq >/dev/null 2>&1 || { echo '{"error": "jq is not installed"}' >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo '{"error": "AWS CLI is not installed"}' >&2; exit 1; }

# Read input from Terraform
input_data=$(cat)
env=$(echo "$input_data" | jq -r '.environment // empty')
bucket_name=$(echo "$input_data" | jq -r '.bucket_name // empty')
output_path=$(echo "$input_data" | jq -r '.output_path // empty')

# Error handling function
error_exit() {
    escaped_error=$(echo "$1" | jq -R .)
    echo "{\"status\": \"error\", \"message\": ${escaped_error}}" >&2
    exit 1
}

# Validate input variables
[ -z "$env" ] && error_exit "Environment variable is not set."
[ -z "$bucket_name" ] && error_exit "Bucket name is not set."
[ -z "$output_path" ] && error_exit "Output path is not set."

# Create a temporary directory
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

# Verify the existence of the backend folder
backend_folder="backend"
if [ ! -d "$backend_folder" ]; then
    error_exit "No 'backend' folder found."
fi

# Copy backend folder to temporary directory
cp -r "$backend_folder" "$temp_dir/backend"

# Change to backend directory and install dependencies
cd "$temp_dir/backend" || error_exit "Failed to change to backend directory."
python -m pip install --upgrade poetry || error_exit "Failed to install Poetry."
poetry install || (poetry lock && poetry install) || error_exit "Failed to install dependencies using Poetry."
chmod +x ./export-deps.sh
./export-deps.sh || error_exit "Failed to execute export-deps.sh."
pip install -r requirements.txt || error_exit "Failed to install requirements.txt dependencies."

# Create a ZIP package
cd "$temp_dir" || error_exit "Failed to change to temporary directory."
if ! zip -r "$output_path" backend -x \*.tf \*sonar-project.properties \*backend-build.sh \*.terraform* \*dev*; then
    error_exit "Failed to create ZIP file."
fi

# Upload to S3
if ! aws s3 cp "$output_path" "s3://$bucket_name/test_backend.zip" --metadata "environment=$env"; then
    error_exit "Failed to upload backend package to S3."
fi

# Output success result in JSON
echo "{\"status\": \"success\", \"bucket\": \"$bucket_name\", \"s3_key\": \"test_backend.zip\"}"
