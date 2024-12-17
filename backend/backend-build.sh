#!/bin/bash
set -euo pipefail

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Error handling function with JSON output
error_exit() {
    local error_message="$1"
    log "ERROR: $error_message"
    jq -n \
        --arg status "error" \
        --arg message "$error_message" \
        '{
            status: $status, 
            message: $message
        }'
    exit 1
}

# Prerequisite checks
check_prerequisites() {
    local missing_commands=()
    for cmd in jq aws python poetry zip; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done

    if [ ${#missing_commands[@]} -gt 0 ]; then
        error_exit "Missing commands: ${missing_commands[*]}"
    fi
}

# Main script execution
main() {
    # Read input from stdin, using jq to parse and validate
    input_data=$(cat | jq '.')

    # Extract values with error handling
    env=$(echo "$input_data" | jq -r '.environment // ""')
    bucket_name=$(echo "$input_data" | jq -r '.bucket_name // ""')
    output_path=$(echo "$input_data" | jq -r '.output_path // ""')

    # Validate inputs
    if [ -z "$env" ]; then
        error_exit "Environment not specified"
    fi
    if [ -z "$bucket_name" ]; then
        error_exit "Bucket name not specified"
    fi
    if [ -z "$output_path" ]; then
        error_exit "Output path not specified"
    fi

    # Prerequisite check
    check_prerequisites

    # Create temporary directory
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    # Get script and backend directory paths
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    backend_folder="$(dirname "$script_dir")/backend"

    # Validate backend folder
    if [ ! -d "$backend_folder" ]; then
        error_exit "Backend folder not found at $backend_folder"
    fi

    # Create temporary copy of backend folder
    cp -r "$backend_folder" "$temp_dir/backend"

    # Create ZIP file
    cd "$temp_dir" || error_exit "Failed to change to temporary directory"
    if ! zip -r "$output_path" backend >&2; then
        error_exit "Failed to create ZIP file"
    fi

    # Upload to S3
    if ! aws s3 cp "$output_path" "s3://$bucket_name/tt_backend.zip" \
        --metadata "environment=$env" >&2; then
        error_exit "Failed to upload backend package to S3"
    fi

    # Retrieve version ID
    version_id=$(aws s3api head-object \
        --bucket "$bucket_name" \
        --key "tt_backend.zip" \
        --query 'VersionId' \
        --output text 2>/dev/null) || error_exit "Failed to get version ID"

    # Get list of packaged files
    packaged_files=($(find "$temp_dir/backend" -type f -printf "%P\n"))
    packaged_files_string=$(printf '%s,' "${packaged_files[@]}" | sed 's/,$//')

    # Generate JSON output
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
}

# Execute main function
main
