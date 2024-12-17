#!/bin/bash
set -euo pipefail

## Check for required commands
command -v jq >/dev/null 2>&1 || { echo '{"error": "jq is not installed"}' >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo '{"error": "AWS CLI is not installed"}' >&2; exit 1; }
command -v zip >/dev/null 2>&1 || { echo '{"error": "zip is not installed"}' >&2; exit 1; }
command -v python >/dev/null 2>&1 || { echo '{"error": "python is not installed"}' >&2; exit 1; }

# Load JSON input using jq
input_data=$(cat)
env=$(echo "$input_data" | jq -r '.environment // empty')
bucket_name=$(echo "$input_data" | jq -r '.bucket_name // empty')
output_path=$(echo "$input_data" | jq -r '.output_path // empty')

# Function for error handling that outputs valid JSON
error_exit() {
    escaped_error=$(echo "$1" | jq -R .)
    echo "{\"status\": \"error\", \"message\": ${escaped_error}}" >&2
    exit 1
}

# Validate input data
validate_input() {
    local var_name="$1"
    local var_value="$2"
    if [ -z "$var_value" ]; then
        error_exit "$var_name is not set in the input data."
    fi
}

validate_input "environment" "$env"
validate_input "bucket_name" "$bucket_name"
validate_input "output_path" "$output_path"

# Create temporary directory
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

# Get the directory where the script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Locate backend folder (parameterized for flexibility)
backend_folder="${BACKEND_FOLDER:-$(dirname "$script_dir")/backend}"
if [ ! -d "$backend_folder" ]; then
    error_exit "No 'backend' folder found at: $backend_folder"
fi

# Create temporary copy of backend folder
cp -r "$backend_folder" "$temp_dir/backend"

# Change to the backend directory and install dependencies using Poetry
cd "$temp_dir/backend" || error_exit "Failed to change to backend directory"

# Ensure Poetry is installed
python -m pip install --upgrade poetry || error_exit "Failed to install Poetry"

# Run Poetry to install dependencies
poetry install || (poetry lock && poetry install) || error_exit "Failed to install dependencies with Poetry"

# Make the export-deps.sh script executable and run it to export requirements.txt
chmod +x ./export-deps.sh
./export-deps.sh || error_exit "Failed to run export-deps.sh"

# Install Python dependencies via pip (from the generated requirements.txt)
pip install -r requirements.txt || error_exit "Failed to install dependencies from requirements.txt"

# Create ZIP file from temporary directory
cd "$temp_dir" || error_exit "Failed to change to temporary directory"
if ! zip -r "$output_path" backend -x "*.tf" "*sonar-project.properties" "*backend-build.sh" "*.terraform*" "*dev*" >&2; then
    error_exit "Failed to create ZIP file"
fi

# Upload to S3 as test_backend.zip
upload_key="test_backend.zip"
if ! aws s3 cp "$output_path" "s3://$bucket_name/$upload_key" --metadata "environment=$env" >&2; then
    error_exit "Failed to upload backend package to S3"
fi

# Retrieve version ID of uploaded object
version_id=$(aws s3api head-object \
    --bucket "$bucket_name" \
    --key "$upload_key" \
    --query 'VersionId' \
    --output text 2>/dev/null) || error_exit "Failed to get version ID of uploaded object"

# Get list of packaged files
packaged_files=($(find "$temp_dir/backend" -type f -printf "%P\n"))
packaged_files_string=$(printf '%s,' "${packaged_files[@]}" | sed 's/,$//')

# Output final JSON result
echo "{
    \"status\": \"success\",
    \"message\": \"Backend package created and uploaded to S3\",
    \"environment\": \"$env\",
    \"bucket\": \"$bucket_name\",
    \"version_id\": \"$version_id\",
    \"key\": \"$upload_key\",
    \"packaged_count\": \"${#packaged_files[@]}\",
    \"packaged_files\": \"$packaged_files_string\"
}"
