#!/bin/bash
set -euo pipefail

# Comprehensive debugging log file
DEBUG_LOG="/tmp/backend-build-full-debug.log"

# Redirect all output (stdout and stderr) to a comprehensive log
exec > >(tee -a "$DEBUG_LOG") 2>&1

# Enhanced error handling function
error_exit() {
    local error_message="$1"
    echo "ERROR: $error_message" >&2
    # Output a valid JSON error for Terraform
    jq -n \
        --arg error "$error_message" \
        '{error: $error}' >&2
    exit 1
}

# Log start of script
echo "Backend Build Script Started: $(date)"
echo "Current Working Directory: $(pwd)"
echo "Script Location: $0"

# Print environment variables
echo "Environment Variables:"
env

# Validate input
input_data=$(cat)
echo "Raw Input Data: $input_data"

# Try to parse input with verbose error handling
parse_input() {
    local key="$1"
    local value
    value=$(echo "$input_data" | jq -r ".$key // empty")
    if [ -z "$value" ]; then
        error_exit "Missing or empty input: $key"
    fi
    echo "$value"
}

# Parse inputs with detailed logging
env=$(parse_input "environment")
bucket_name=$(parse_input "bucket_name")
output_path=$(parse_input "output_path")

echo "Parsed Inputs:"
echo "Environment: $env"
echo "Bucket Name: $bucket_name"
echo "Output Path: $output_path"

# Prerequisite checks
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error_exit "Required command not found: $1"
    fi
    echo "Command verified: $1"
}

# Check required commands
check_command jq
check_command aws
check_command python
check_command poetry
check_command zip

# Create temporary directory
temp_dir=$(mktemp -d)
echo "Temporary Directory: $temp_dir"
trap 'rm -rf "$temp_dir"' EXIT

# Get script and backend directories
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backend_folder="$(dirname "$script_dir")/backend"

echo "Script Directory: $script_dir"
echo "Backend Folder: $backend_folder"

# Validate backend folder
if [ ! -d "$backend_folder" ]; then
    error_exit "Backend folder not found: $backend_folder"
fi

# Comprehensive build process with extensive logging
{
    echo "Copying backend folder..."
    cp -r "$backend_folder" "$temp_dir/backend"

    echo "Changing to backend directory..."
    cd "$temp_dir/backend"

    echo "Installing dependencies..."
    python -m pip install --upgrade poetry
    poetry install || (poetry lock && poetry install)

    echo "Exporting dependencies..."
    chmod +x ./export-deps.sh
    ./export-deps.sh
    pip install -r requirements.txt

    echo "Creating ZIP file..."
    cd "$temp_dir"
    zip -r "$output_path" backend -x \*.tf \*sonar-project.properties \*backend-build.sh \*.terraform* \*dev*

    echo "Uploading to S3..."
    aws s3 cp "$output_path" "s3://$bucket_name/tt_backend.zip" \
        --metadata "environment=$env"

    echo "Retrieving version ID..."
    version_id=$(aws s3api head-object \
        --bucket "$bucket_name" \
        --key "tt_backend.zip" \
        --query 'VersionId' \
        --output text)

    echo "Collecting packaged files..."
    packaged_files=($(find "$temp_dir/backend" -type f -printf "%P\n"))
    packaged_files_string=$(printf '%s,' "${packaged_files[@]}" | sed 's/,$//')

    # Final JSON output
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

} || error_exit "Build process failed"

echo "Backend Build Script Completed Successfully: $(date)"
