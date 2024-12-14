#!/bin/bash
# Lambda Packaging and S3 Upload Script for Terraform External Data Source

# Strict error handling
set -euo pipefail

# Ensure JSON-compatible error handling
json_error_exit() {
    local error_message="$1"
    # Ensure clean JSON output with only string values
    jq -n --arg msg "$error_message" '{
        "error": $msg,
        "status": "failed",
        "bucket": "",
        "s3_key": "",
        "layer_s3_key": "",
        "version_id": "",
        "message": "",
        "environment": "",
        "layer_packaged_count": "0",
        "function_packaged_count": "0"
    }' >&2
    exit 1
}

# Validate commands
validate_commands() {
    local commands=("jq" "aws" "zip")
    for cmd in "${commands[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || json_error_exit "$cmd is not installed"
    done
}

# Main packaging and upload script
main() {
    # Validate required commands
    validate_commands

    # Read JSON input from stdin
    input_data=$(cat)
    
    # Extract input parameters with jq
    env=$(echo "$input_data" | jq -r '.environment // ""')
    bucket_name=$(echo "$input_data" | jq -r '.bucket_name // ""')
    output_path_layer=$(echo "$input_data" | jq -r '.output_path_layer // ""')
    output_path_function=$(echo "$input_data" | jq -r '.output_path_function // ""')

    # Validate input parameters
    [[ -z "$env" ]] && json_error_exit "Environment not specified"
    [[ -z "$bucket_name" ]] && json_error_exit "S3 Bucket name not specified"
    [[ -z "$output_path_layer" ]] && json_error_exit "Layer output path not specified"
    [[ -z "$output_path_function" ]] && json_error_exit "Function output path not specified"

    # Create temporary working directory
    temp_dir=$(mktemp -d) || json_error_exit "Failed to create temporary directory"
    trap 'rm -rf "$temp_dir"' EXIT

    # Get script and source directory paths
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    api_folder="$script_dir/api"
    backend_folder="$(dirname "$script_dir")/backend"

    # Validate source folders
    [[ ! -d "$api_folder" ]] && json_error_exit "API folder not found: $api_folder"
    [[ ! -d "$backend_folder" ]] && json_error_exit "Backend folder not found: $backend_folder"

    # Create temporary copies
    cp -r "$api_folder" "$temp_dir/api"
    cp -r "$backend_folder" "$temp_dir/backend"

    # Exclusion list for backend function ZIP
    exclusion_list=(
        "*.tfstate"
        ".terraform/*"
        "*.log"
        "*.tmp"
        "node_modules/*"
        ".git/*"
        "*.env"
        "main.tf"
        "*.tfbackend"
        "export-deps.sh"
        "backend-build.sh"
    )

    # Create exclude file
    exclude_file="$temp_dir/exclude_list.txt"
    printf "%s\n" "${exclusion_list[@]}" > "$exclude_file"

    # ZIP Lambda Layer (API folder)
    cd "$temp_dir" || json_error_exit "Failed to change to temp directory"
    zip -r "$output_path_layer" api >&2 || json_error_exit "Failed to create Lambda Layer ZIP"

    # ZIP Lambda Function (Backend folder)
    cd "$temp_dir/backend" || json_error_exit "Failed to change to backend directory"
    zip -r "$output_path_function" . -x@"$exclude_file" >&2 || json_error_exit "Failed to create Lambda Function ZIP"

    # Verify ZIP files were created
    [[ ! -f "$output_path_layer" ]] && json_error_exit "Lambda Layer ZIP not created"
    [[ ! -f "$output_path_function" ]] && json_error_exit "Lambda Function ZIP not created"

    # Upload Lambda Layer to S3
    aws s3 cp "$output_path_layer" "s3://$bucket_name/tt_lambda_layer.zip" \
        --metadata "environment=$env" >&2 || json_error_exit "Failed to upload Lambda Layer to S3"

    # Upload Lambda Function to S3
    aws s3 cp "$output_path_function" "s3://$bucket_name/tt_lambda_function.zip" \
        --metadata "environment=$env" >&2 || json_error_exit "Failed to upload Lambda Function to S3"

    # Prepare JSON output for Terraform
    layer_file_count=$(find "$temp_dir/api" -type f | wc -l)
    function_file_count=$(find "$temp_dir/backend" -type f | wc -l)

    # Use jq to ensure consistent, valid JSON output
    jq -n \
        --arg bucket "$bucket_name" \
        --arg s3_key "tt_lambda_function.zip" \
        --arg layer_s3_key "tt_lambda_layer.zip" \
        --arg version_id "$(date +%s)" \
        --arg status "success" \
        --arg message "Lambda Layer and Function packages created and uploaded to S3" \
        --arg environment "$env" \
        --arg layer_count "$layer_file_count" \
        --arg function_count "$function_file_count" \
    '{
        "bucket": $bucket,
        "s3_key": $s3_key,
        "layer_s3_key": $layer_s3_key,
        "version_id": $version_id,
        "status": $status, 
        "message": $message,
        "environment": $environment,
        "layer_packaged_count": $layer_count,
        "function_packaged_count": $function_count
    }'
}

# Execute main function
main
