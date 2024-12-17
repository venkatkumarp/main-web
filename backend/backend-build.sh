#!/bin/bash
set -euo pipefail

## Check for required commands
command -v jq >/dev/null 2>&1 || { echo '{"error": "jq is not installed"}' >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo '{"error": "AWS CLI is not installed"}' >&2; exit 1; }

# Load JSON input using jq
input_data=$(cat)
env=$(echo "$input_data" | jq -r '.environment // empty')
bucket_name=$(echo "$input_data" | jq -r '.bucket_name // empty')
output_path=$(echo "$input_data" | jq -r '.output_path // empty')

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
if [ -z "$output_path" ]; then
    error_exit "output_path variable is not set in the input data."
fi

# Create temporary directory
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

# Get the directory where the script is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for backend folder
backend_folder="$(dirname "$script_dir")/backend"
if [ ! -d "$backend_folder" ]; then
    error_exit "No 'backend' folder found"
fi

# Suppress stdout, redirect stderr to /dev/null to prevent any debug output
{
    # Create temporary copy of backend folder
    cp -r "$backend_folder" "$temp_dir/backend"

    # Change to the backend directory and install dependencies
    cd "$temp_dir/backend"
    python -m pip install --upgrade poetry
    poetry install || (poetry lock && poetry install)
    chmod +x ./export-deps.sh
    ./export-deps.sh
    pip install -r requirements.txt

    # Create ZIP file from temporary directory
    cd "$temp_dir"
    zip -r "$output_path" backend -x \*.tf \*sonar-project.properties \*backend-build.sh \*.terraform* \*dev*

    # Upload to S3 as tt_backend.zip
    aws s3 cp "$output_path" "s3://$bucket_name/tt_backend.zip" \
        --metadata "environment=$env"

    # Retrieve version ID of uploaded object
    version_id=$(aws s3api head-object \
        --bucket "$bucket_name" \
        --key "tt_backend.zip" \
        --query 'VersionId' \
        --output text)

    # Get list of packaged files
    packaged_files=($(find "$temp_dir/backend" -type f -printf "%P\n"))
    packaged_files_string=$(printf '%s,' "${packaged_files[@]}" | sed 's/,$//')

    # Output final JSON result
    jq -n \
        --arg status "success" \
        --arg message "Backend package created and uploaded to S3" \
        --arg environment "$env" \
        --arg bucket "$bucket_name" \
        --arg version_id "$version_id" \
        --arg s3_key "tt_backend.zip" \
        --arg packaged_count "${#packaged_files[@]}" \
        --arg packaged_files "$packaged_files_string" \
        '{
            status: $status,
            message: $message,
            environment: $environment,
            bucket: $bucket,
            version_id: $version_id,
            s3_key: $s3_key,
            packaged_count: $packaged_count,
            packaged_files: $packaged_files
        }'
} 2>/dev/null
