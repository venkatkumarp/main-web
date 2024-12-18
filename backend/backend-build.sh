#!/bin/bash
set -euo pipefail

# Strict error handling with JSON output
error_exit() {
    # Use printf to ensure clean JSON output
    printf '{"status":"error","message":"%s"}' "${1//\"/\\\"}"
    exit 1
}

# Validate required commands
check_prerequisites() {
    for cmd in jq aws python3 poetry zip; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error_exit "Required command not found: $cmd"
        fi
    done
}

# Main script execution
main() {
    # Read and validate input
    input_data=$(cat)

    # Parse input using jq
    env=$(echo "$input_data" | jq -r '.environment // ""')
    bucket_name=$(echo "$input_data" | jq -r '.bucket_name // ""')
    output_path=$(echo "$input_data" | jq -r '.output_path // ""')

    # Validate inputs
    [ -z "$env" ] && error_exit "Environment not specified"
    [ -z "$bucket_name" ] && error_exit "Bucket name not specified"
    [ -z "$output_path" ] && error_exit "Output path not specified"

    # Check prerequisites
    check_prerequisites

    # Create temporary working directory
    temp_dir=$(mktemp -d)
    trap 'rm -rf "$temp_dir"' EXIT

    # Locate backend folder
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    backend_folder="$(dirname "$script_dir")/backend"

    # Validate backend folder exists
    [ ! -d "$backend_folder" ] && error_exit "Backend folder not found"

    # Prepare virtual environment
    python3 -m venv "$temp_dir/venv"
    source "$temp_dir/venv/bin/activate"

    # Install Poetry and dependencies
    pip install poetry
    cp -r "$backend_folder" "$temp_dir/backend"
    cd "$temp_dir/backend"

    # Export dependencies
    poetry export --without-hashes -o requirements.txt
    pip install -r requirements.txt

    # Create zip package
    cd "$temp_dir"
    zip -r "$output_path" backend venv \
        -x "*.git/*" "*.terraform/*" "*.env" "*.gitignore"

    # Upload to S3
    aws s3 cp "$output_path" "s3://$bucket_name/tt_backend.zip" \
        --metadata "environment=$env"

    # Get version ID
    version_id=$(aws s3api head-object \
        --bucket "$bucket_name" \
        --key "tt_backend.zip" \
        --query 'VersionId' \
        --output text)

    # Prepare files list
    packaged_files=$(find "$temp_dir/backend" -type f | 
        sed 's|^'"$temp_dir/backend/"'||' | 
        jq -R . | 
        jq -s .)

    # Generate clean JSON output using jq
    jq -n \
        --arg status "success" \
        --arg message "Backend package created and uploaded to S3" \
        --arg environment "$env" \
        --arg bucket "$bucket_name" \
        --arg version_id "$version_id" \
        --arg s3_key "tt_backend.zip" \
        --argjson packaged_count "$(find "$temp_dir/backend" -type f | wc -l)" \
        --argjson packaged_files "$packaged_files" \
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
