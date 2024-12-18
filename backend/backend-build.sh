#!/bin/bash
set -euo pipefail

# Check for required commands
command -v jq >/dev/null 2>&1 || { echo '{"error": "jq is not installed"}' >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo '{"error": "AWS CLI is not installed"}' >&2; exit 1; }

# Check if Poetry is installed, and install it if it's missing
if ! command -v poetry >/dev/null 2>&1; then
    echo "Poetry is not installed globally. Installing Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -
fi

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

# Step 1: Create a Python virtual environment
echo "Creating virtual environment in $temp_dir/venv"
python3 -m venv "$temp_dir/venv"

# Step 2: Activate the virtual environment
echo "Activating the virtual environment"
source "$temp_dir/venv/bin/activate"

# Step 3: Install Poetry inside the virtual environment
echo "Installing Poetry inside the virtual environment"
pip install poetry

# Step 4: Export dependencies from Poetry to requirements.txt
cd "$temp_dir/backend" || error_exit "Failed to change to backend directory"
echo "Exporting dependencies from Poetry to requirements.txt..."
poetry export --without-hashes -o requirements.txt

# Step 5: Install dependencies into the virtual environment
echo "Installing dependencies into the virtual environment..."
pip install -r "$temp_dir/backend/requirements.txt"

# Step 6: Include the virtual environment and backend code in the zip
echo "Zipping backend code and virtual environment..."
zip -r "$output_path" "$temp_dir/backend" "$temp_dir/venv" -x "*.git/*" "*.terraform/*" "*.env" "*.gitignore"  # Exclude unnecessary files

# Step 7: Upload to S3 as tt_backend.zip
if aws s3 cp "$output_path" "s3://$bucket_name/tt_backend.zip" \
    --metadata "environment=$env" >&2; then
    echo "Successfully uploaded backend package to S3 as tt_backend.zip" >&2
else
    error_exit "Failed to upload backend package to S3"
fi

# Step 8: Retrieve version ID of uploaded object
version_id=$(aws s3api head-object \
    --bucket "$bucket_name" \
    --key "tt_backend.zip" \
    --query 'VersionId' \
    --output text 2>/dev/null) || error_exit "Failed to get version ID"

# Step 9: Get list of packaged files
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
    \"packaged_files\": [$packaged_files_string]
}"
