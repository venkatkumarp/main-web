#!/bin/bash

# Exit on any error
set -e

# Read inputs from Terraform
ENVIRONMENT=$1
BUCKET_NAME=$2
OUTPUT_PATH=$3

# Function to handle errors
function handle_error {
    echo "{\"status\":\"failure\", \"message\":\"Error: $1\"}"
    exit 1
}

# Upgrade Poetry if necessary
echo "Upgrading Poetry..."
python3 -m pip install --upgrade poetry || handle_error "Failed to upgrade poetry"

# Install dependencies with poetry, with fallback if needed
echo "Installing dependencies with Poetry..."
if ! poetry install; then
    echo "Poetry install failed, running poetry lock and poetry install..."
    poetry lock || handle_error "Poetry lock failed"
    poetry install || handle_error "Poetry install failed after lock"
fi

# Make the export-deps.sh executable and run it
echo "Making export-deps.sh executable..."
chmod +x ./export-deps.sh || handle_error "Failed to make export-deps.sh executable"

echo "Running export-deps.sh..."
./export-deps.sh || handle_error "Failed to execute export-deps.sh"

# Install additional dependencies from requirements.txt
echo "Installing dependencies from requirements.txt..."
pip install -r requirements.txt || handle_error "Failed to install dependencies from requirements.txt"

# Zip the backend folder
echo "Zipping the backend folder into $OUTPUT_PATH..."
zip -r $OUTPUT_PATH . || handle_error "Failed to zip the backend folder"

# Upload the zip file to S3
echo "Uploading the zip file to S3..."
aws s3 cp $OUTPUT_PATH s3://$BUCKET_NAME/backend.zip || handle_error "Failed to upload the zip file to S3"

# Return result as JSON to Terraform
echo "{\"output_path\":\"$OUTPUT_PATH\", \"bucket_name\":\"$BUCKET_NAME\", \"status\":\"success\", \"message\":\"Backend packaging and upload successful\"}"
