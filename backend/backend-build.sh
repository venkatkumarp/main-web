#!/bin/bash
set -euo pipefail

# Determine the script's directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verify the 'backend' folder relative to the script's directory
backend_folder="${script_dir}"
if [ ! -d "$backend_folder" ]; then
    echo "Error: Backend folder not found in $backend_folder"
    exit 1
fi

# Change to the backend directory
cd "$backend_folder" || { echo "Failed to change to backend directory"; exit 1; }

# Install dependencies
python -m pip install --upgrade poetry || { echo "Failed to install Poetry"; exit 1; }
poetry install || (poetry lock && poetry install) || { echo "Failed to install dependencies using Poetry"; exit 1; }
chmod +x ./export-deps.sh
./export-deps.sh || { echo "Failed to execute export-deps.sh"; exit 1; }
pip install -r requirements.txt || { echo "Failed to install requirements.txt dependencies"; exit 1; }

# Create a ZIP package
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
cd "$temp_dir" || { echo "Failed to change to temporary directory"; exit 1; }
if ! zip -r "$output_path" "$backend_folder" -x \*.tf \*sonar-project.properties \*backend-build.sh \*.terraform* \*dev*; then
    echo "Failed to create ZIP file"
    exit 1
fi

# Upload to S3
if ! aws s3 cp "$output_path" "s3://$bucket_name/test_backend.zip" --metadata "environment=$env"; then
    echo "Failed to upload backend package to S3"
    exit 1
fi

# Output success result in JSON
echo "{\"status\": \"success\", \"bucket\": \"$bucket_name\", \"s3_key\": \"test_backend.zip\"}"
