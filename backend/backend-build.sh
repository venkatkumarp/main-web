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
    # Ensure JSON output for Terraform
    jq -n \
        --arg error "$error_message" \
        '{error: $error}' >&2
    exit 1
}

# Log start of script
echo "Backend Build Script Started: $(date)"
echo "Current Working Directory: $(pwd)"
echo "Script Location: $0"

# Check and install Python if needed
if ! command -v python3 >/dev/null 2>&1; then
    echo "Python3 not found. Attempting to install..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y python3 python3-pip
    elif command -v brew >/dev/null 2>&1; then
        brew install python
    else
        error_exit "Unable to install Python. Please install manually."
    fi
fi

# Ensure pip is up to date
python3 -m pip install --upgrade pip

# Check and install Poetry if needed
if ! command -v poetry >/dev/null 2>&1; then
    echo "Poetry not found. Installing..."
    curl -sSL https://install.python-poetry.org | python3 -
    
    # Add Poetry to PATH if not already there
    if [ -f "$HOME/.poetry/env" ]; then
        source "$HOME/.poetry/env"
    elif [ -f "$HOME/.local/bin/poetry" ]; then
        export PATH="$HOME/.local/bin:$PATH"
    else
        error_exit "Failed to install Poetry"
    fi
fi

# Print Python and Poetry versions
echo "Python Version: $(python3 --version)"
echo "Poetry Version: $(poetry --version)"

# Read and validate JSON input
input_data=$(cat)
echo "Raw Input Data: $input_data"

# Validate JSON input using jq
if ! echo "$input_data" | jq empty >/dev/null 2>&1; then
    error_exit "Invalid JSON input"
fi

# Parse inputs with jq
parse_input() {
    local key="$1"
    local value
    value=$(echo "$input_data" | jq -r ".$key // empty")
    if [ -z "$value" ]; then
        error_exit "Missing or empty input: $key"
    fi
    echo "$value"
}

# Parse required inputs
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

# Check remaining required commands
check_command jq
check_command aws
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

    echo "Installing dependencies with Poetry..."
    poetry env use python3
    poetry install || (poetry lock && poetry install)

    # Attempt to export dependencies if export script exists
    if [ -f "./export-deps.sh" ]; then
        echo "Exporting dependencies..."
        chmod +x ./export-deps.sh
        ./export-deps.sh
    fi

    # Fallback dependency installation
    if [ -f "requirements.txt" ]; then
        echo "Installing requirements..."
        poetry run pip install -r requirements.txt
    fi

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

    # Final JSON output with error handling
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
