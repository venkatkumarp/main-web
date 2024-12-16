#!/bin/bash
set -euo pipefail

# Function for JSON-safe error handling
error_exit() {
    local error_message="$1"
    # Escape the error message for JSON
    escaped_error=$(printf '%s' "$error_message" | jq -R -s '.')
   
    # Output error as JSON to stderr
    printf '{"status": "error", "message": %s}\n' "$escaped_error" >&2
   
    # Exit with error status
    exit 1
}

# Install Python if not already installed
install_python() {
    # Check if Python is installed
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Python3 not found. Attempting to install..."
        
        # Detect package manager and install Python
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

    # Ensure pip is installed and up to date
    python3 -m ensurepip --upgrade
    python3 -m pip install --upgrade pip
}

# Install Poetry
install_poetry() {
    # First, ensure Python is installed
    install_python

    # Check if Poetry is installed
    if ! command -v poetry >/dev/null 2>&1; then
        echo "Poetry not found. Installing..."
        
        # Use pip to install Poetry
        python3 -m pip install poetry

        # Verify Poetry installation
        if ! command -v poetry >/dev/null 2>&1; then
            error_exit "Failed to install Poetry"
        fi
    fi
}

# Install prerequisite tools
install_prerequisites() {
    # Ensure Python is installed first
    install_python

    # List of tools to check and install
    local tools=("jq" "aws" "zip")
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update
                sudo apt-get install -y "$tool"
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y "$tool"
            elif command -v brew >/dev/null 2>&1; then
                brew install "$tool"
            else
                error_exit "$tool is not installed and cannot be automatically installed"
            fi
        fi
    done
}

# Run prerequisite installations in the correct order
install_python
install_prerequisites
install_poetry

# Prerequisite checks (now after installation attempts)
command -v jq >/dev/null 2>&1 || error_exit "jq is not installed"
command -v aws >/dev/null 2>&1 || error_exit "AWS CLI is not installed"
command -v poetry >/dev/null 2>&1 || error_exit "Poetry is not installed"
command -v python3 >/dev/null 2>&1 || error_exit "Python3 is not installed"
command -v zip >/dev/null 2>&1 || error_exit "zip is not installed"

# Read input from stdin
input_data=$(cat)

# Extract required variables with error checking
env=$(echo "$input_data" | jq -r '.environment // empty')
bucket_name=$(echo "$input_data" | jq -r '.bucket_name // empty')
output_path=$(echo "$input_data" | jq -r '.output_path // empty')

# Validate required inputs
[ -z "$env" ] && error_exit "environment variable is required"
[ -z "$bucket_name" ] && error_exit "bucket_name variable is required"
[ -z "$output_path" ] && error_exit "output_path variable is required"

# Create temporary working directory
temp_dir=$(mktemp -d) || error_exit "Failed to create temporary directory"
trap 'rm -rf "$temp_dir"' EXIT

# Determine script and backend folder locations
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backend_folder="$(dirname "$script_dir")/backend"

# Validate backend folder exists
[ ! -d "$backend_folder" ] && error_exit "No 'backend' folder found"

# Copy backend folder to temporary location
cp -r "$backend_folder" "$temp_dir/backend" || error_exit "Failed to copy backend folder"

# Change to backend directory
cd "$temp_dir/backend" || error_exit "Failed to change to backend directory"

# Dependency management with error handling
{
    # Upgrade pip and setuptools
    python3 -m pip install --upgrade pip setuptools

    # Install or update Poetry
    python3 -m pip install --upgrade poetry

    # Install project dependencies
    poetry env use python3
    poetry install || (poetry lock && poetry install)
    
    # Export dependencies
    chmod +x ./export-deps.sh
    ./export-deps.sh
    
    # Install requirements as a fallback
    pip install -r requirements.txt
} || error_exit "Dependency installation failed"

# Create ZIP package
cd "$temp_dir" || error_exit "Failed to change to temporary directory"
zip_output=$(zip -r "$output_path" backend \
    -x \*.tf \*sonar-project.properties \*backend-build.sh \*.terraform* \*dev* 2>&1) \
    || error_exit "ZIP creation failed: $zip_output"

# Upload to S3 with metadata
upload_output=$(aws s3 cp "$output_path" "s3://$bucket_name/tt_backend.zip" \
    --metadata "environment=$env" 2>&1) \
    || error_exit "S3 upload failed: $upload_output"

# Retrieve version ID
version_id=$(aws s3api head-object \
    --bucket "$bucket_name" \
    --key "tt_backend.zip" \
    --query 'VersionId' \
    --output text 2>/dev/null) \
    || error_exit "Failed to retrieve S3 object version ID"

# Generate list of packaged files
packaged_files=($(find "$temp_dir/backend" -type f -printf "%P\n"))
packaged_files_string=$(printf '%s,' "${packaged_files[@]}" | sed 's/,$//')

# Output clean JSON result
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
