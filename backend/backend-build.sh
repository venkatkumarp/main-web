#!/bin/bash
set -euo pipefail

## Check for required commands
command -v jq >/dev/null 2>&1 || { echo '{"error": "jq is not installed"}' >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo '{"error": "AWS CLI is not installed"}' >&2; exit 1; }

# Function for error handling that outputs valid JSON
error_exit() {
    escaped_error=$(echo "$1" | jq -R .)
    echo "{\"status\": \"error\", \"message\": ${escaped_error}}" >&2
    exit 1
}

# Function to install Python
install_python() {
    echo "Installing Python..."
    if command -v python3 >/dev/null 2>&1; then
        echo "Python is already installed."
    else
        echo "Python not found. Installing Python..."
        # Install Python (ensure your system has package management like apt or yum)
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip || error_exit "Failed to install Python using apt-get"
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y python3 python3-pip || error_exit "Failed to install Python using yum"
        else
            error_exit "Unsupported package manager. Please install Python manually."
        fi
    fi
}

# Function to install Poetry
install_poetry() {
    echo "Installing Poetry..."
    if command -v poetry >/dev/null 2>&1; then
        echo "Poetry is already installed."
    else
        echo "Poetry not found. Installing Poetry..."
        # Install Poetry using the official installer
        curl -sSL https://install.python-poetry.org | python3 - || error_exit "Failed to install Poetry"
    fi
}

# Install Python and Poetry if not already installed
install_python
install_poetry

# Load JSON input using jq
input_data=$(cat)
env=$(echo "$input_data" | jq -r '.environment // empty')
bucket_name=$(echo "$input_data" | jq -r '.bucket_name // empty')
output_path=$(echo "$input_data" | jq -r '.output_path // empty')

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

# Create temporary copy of backend folder
cp -r "$backend_folder" "$temp_dir/backend"

# Navigate to the backend folder
cd "$temp_dir/backend" || error_exit "Failed to change to backend directory"

# Try to install dependencies with Poetry
# If installation fails, regenerate the poetry.lock and try again
if [ -f "pyproject.toml" ]; then
    poetry install || (poetry lock && poetry install) || error_exit "Failed to install dependencies with Poetry"
else
    echo "No Poetry configuration found (pyproject.toml). Skipping Poetry installation."
fi

# Create ZIP file from temporary directory
cd "$temp_dir" || error_exit "Failed to change to temporary directory"
if ! zip -r "$output_path" backend >&2; then
    error_exit "Failed to create ZIP file"
fi

# Upload to S3 as tt_backend.zip
if aws s3 cp "$output_path" "s3://$bucket_name/tt_backend.zip" \
    --metadata "environment=$env" >&2; then
    echo "Successfully uploaded backend package to S3 as tt_backend.zip" >&2
else
    error_exit "Failed to upload backend package to S3"
fi

# Retrieve version ID of uploaded object
version_id=$(aws s3api head-object \
    --bucket "$bucket_name" \
    --key "tt_backend.zip" \
    --query 'VersionId' \
    --output text 2>/dev/null) || error_exit "Failed to get version ID"

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
    \"s3_key\": \"tt_backend.zip\",
    \"packaged_count\": \"${#packaged_files[@]}\",
    \"packaged_files\": \"$packaged_files_string\"
}"
