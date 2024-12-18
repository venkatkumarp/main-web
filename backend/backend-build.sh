#!/bin/bash
set -euo pipefail

# Determine the script's directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read input data
input_data=$(cat)
env=$(echo "$input_data" | jq -r '.environment // empty')
bucket_name=$(echo "$input_data" | jq -r '.bucket_name // empty')
output_path=$(echo "$input_data" | jq -r '.output_path // "/tmp/backend.zip"')

# Error handling function
error_exit() {
    escaped_error=$(echo "$1" | jq -R .)
    echo "{\"status\": \"error\", \"message\": ${escaped_error}}" >&2
    exit 1
}

# Validate input variables
[ -z "$env" ] && error_exit "Environment variable is not set."
[ -z "$bucket_name" ] && error_exit "Bucket name is not set."

# Change to backend directory
backend_folder="$script_dir"
if [ ! -d "$backend_folder" ]; then
    error_exit "No 'backend' folder found in $backend_folder."
fi
cd "$backend_folder" || error_exit "Failed to change to backend directory."

# Install Poetry and dependencies
python -m pip install --upgrade poetry || error_exit "Failed to install Poetry."
poetry self add poetry-plugin-export || error_exit "Failed to add poetry-plugin-export."
poetry lock --no-update || error_exit "Failed to update poetry.lock."
poetry install --no-root || error_exit "Failed to install dependencies using Poetry."

# Run export-deps script
chmod +x ./export-deps.sh
./export-deps.sh || error_exit "Failed to execute export-deps.sh."

# Install Python dependencies
pip install -r requirements.txt || error_exit "Failed to install requirements.txt dependencies."

# Create a ZIP package
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
cd "$temp_dir" || error_exit "Failed to change to temporary directory."
if ! zip -r "$output_path" "$backend_folder" -x \*.tf \*sonar-project.properties \*backend-build.sh \*.terraform* \*dev*; then
    error_exit "Failed to create ZIP file."
fi

# Upload to S3
if ! aws s3 cp "$output_path" "s3://$bucket_name/test_backend.zip" --metadata "environment=$env"; then
    error_exit "Failed to upload backend package to S3."
fi

# Output success result in JSON
echo "{\"status\": \"success\", \"bucket\": \"$bucket_name\", \"s3_key\": \"test_backend.zip\"}"
