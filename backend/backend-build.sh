#!/bin/bash
# Extensive debugging script

# Debug function to output trace information
debug_trace() {
    echo "DEBUG: $*" >&2
}

# Redirect all output to a log file for detailed tracing
exec > >(tee /tmp/backend_build_stdout.log) 2> >(tee /tmp/backend_build_stderr.log >&2)

# Debugging output at the start
debug_trace "Script started"
debug_trace "Current directory: $(pwd)"
debug_trace "Script path: $0"

# Print environment and input
set -x # Print each command as it's executed

#!/bin/bash
set -euo pipefail

# Comprehensive logging and error handling
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Robust JSON error handling
error_exit() {
    local error_message="$1"
    log "ERROR: $error_message"
    
    # Ensure clean, valid JSON output
    printf '{"status":"error","message":"%s"}' "${error_message//\"/\\\"}" >&2
    exit 1
}

# Prerequisite checks
check_prerequisites() {
    for cmd in jq aws python poetry zip; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error_exit "Required command not found: $cmd"
        fi
    done
}

# Main script execution
main() {
    # Debug: Print raw input
    debug_trace "Raw input:"
    cat
    debug_trace "Input reading complete"

    # Read and parse input
    input_data=$(cat)
    debug_trace "Input data: $input_data"

    # Robust input parsing with default empty strings
    env=$(echo "$input_data" | jq -r '.environment // ""')
    bucket_name=$(echo "$input_data" | jq -r '.bucket_name // ""')
    output_path=$(echo "$input_data" | jq -r '.output_path // ""')

    # Validate inputs
    [ -z "$env" ] && error_exit "Environment not specified"
    [ -z "$bucket_name" ] && error_exit "Bucket name not specified"
    [ -z "$output_path" ] && error_exit "Output path not specified"

    # Prerequisite check
    check_prerequisites

    # Create temporary directory
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    # Locate backend folder
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    backend_folder="$(dirname "$script_dir")/backend"

    # Validate backend folder
    [ ! -d "$backend_folder" ] && error_exit "Backend folder not found"

    # Copy backend files
    cp -r "$backend_folder" "$temp_dir/backend"

    # Create ZIP
    cd "$temp_dir" || error_exit "Directory change failed"
    debug_trace "Creating ZIP file"
    zip -r "$output_path" backend

    # S3 Upload
    debug_trace "Uploading to S3"
    aws s3 cp "$output_path" "s3://$bucket_name/tt_backend.zip" \
        --metadata "environment=$env"

    # Get version ID
    version_id=$(aws s3api head-object \
        --bucket "$bucket_name" \
        --key "tt_backend.zip" \
        --query 'VersionId' \
        --output text)

    # Prepare file list
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

# Final debug trace
debug_trace "Script completed successfully"
