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
        }' >&2
    exit 1
}

# Install Python if not available
install_python() {
    if ! command -v python &> /dev/null; then
        log "Python is not installed. Installing Python..."
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip
        sudo ln -s /usr/bin/python3 /usr/bin/python
    fi
}

# Install dependencies
install_dependencies() {
    log "Installing dependencies..."
    python -m pip install --upgrade poetry
    poetry install || (poetry lock && poetry install)
    
    chmod +x ./export-deps.sh
    ./export-deps.sh
    pip install -r requirements.txt
}

# Check required commands
check_prerequisites() {
    for cmd in jq aws; do
        command -v "$cmd" >/dev/null 2>&1 || error_exit "$cmd is not installed"
    done
}

# Main script execution
main() {
    # Read input from stdin
    input_data=$(cat)

    # Parse input using jq
    env=$(echo "$input_data" | jq -r '.environment // empty')
    bucket_name=$(echo "$input_data" | jq -r '.bucket_name // empty')
    output_path=$(echo "$input_data" | jq -r '.output_path // empty')

    # Validate input variables
    if [ -z "$env" ]; then
        error_exit "environment variable is not set in the input data"
    fi
    if [ -z "$bucket_name" ]; then
        error_exit "bucket_name variable is not set in the input data"
    fi
    if [ -z "$output_path" ]; then
        error_exit "output_path variable is not set in the input data"
    fi

    # Install prerequisites
    install_python
    install_dependencies
    check_prerequisites

    # Create temporary directory
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    # Get script and backend directory paths
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    backend_folder="$(dirname "$script_dir")/backend"

    # Validate backend folder
    if [ ! -d "$backend_folder" ]; then
        error_exit "No 'backend' folder found"
    fi

    # Create temporary copy of backend folder
    log "Copying backend files to temporary directory..."
    cp -r "$backend_folder" "$temp_dir/backend"

    # Create ZIP file
    cd "$temp_dir" || error_exit "Failed to change to temporary directory"
    log "Creating ZIP archive..."
    if ! zip -r "$output_path" backend >&2; then
        error_exit "Failed to create ZIP file"
    fi

    # Upload to S3
    log "Uploading to S3..."
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
