#!/bin/bash
set -euo pipefail

# Function for error handling that outputs valid JSON
error_exit() {
    escaped_error=$(echo "$1" | jq -R .)
    echo "{\"status\": \"error\", \"message\": ${escaped_error}}" >&2
    exit 1
}

# Function to install Python using pyenv
install_python() {
    # Check if pyenv is installed
    if ! command -v pyenv &> /dev/null; then
        echo "Installing pyenv..." >&2
        
        # Install pyenv dependencies
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update
            sudo apt-get install -y make build-essential libssl-dev zlib1g-dev \
                libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
                libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev \
                liblzma-dev python3-dev
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install pyenv
        else
            error_exit "Unsupported OS for pyenv installation"
        fi

        # Install pyenv
        curl https://pyenv.run | bash
        
        # Update shell configuration
        export PATH="$HOME/.pyenv/bin:$PATH"
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
    fi

    # Install Python version (replace with desired version)
    PYTHON_VERSION="3.9.7"
    pyenv install -s "$PYTHON_VERSION"
    pyenv global "$PYTHON_VERSION"
}

# Function to install Poetry
install_poetry() {
    # Check if Poetry is installed
    if ! command -v poetry &> /dev/null; then
        echo "Installing Poetry..." >&2
        
        # Install Poetry
        curl -sSL https://install.python-poetry.org | python3 -
        
        # Ensure Poetry is in PATH
        export PATH="/home/$(whoami)/.local/bin:$PATH"
    fi

    # Verify Poetry installation
    poetry --version || error_exit "Poetry installation failed"
}

# Check for required commands
command -v jq >/dev/null 2>&1 || { echo '{"error": "jq is not installed"}' >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo '{"error": "AWS CLI is not installed"}' >&2; exit 1; }

# Install Python and Poetry
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

# Change to backend directory and install dependencies
cd "$temp_dir/backend"

# Install project dependencies with Poetry
poetry config virtualenvs.create true
poetry install || error_exit "Failed to install project dependencies"

# Return to temporary directory
cd "$temp_dir"

# Create ZIP file from temporary directory
if ! zip -r "$output_path" backend -x \*.tf \*sonar-project.properties \*backend-build.sh \*.terraform* \*dev* >&2; then
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
