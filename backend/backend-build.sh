#!/bin/bash
set -euo pipefail

# Strict JSON error function
json_error() {
    printf '{"status": "error", "message": "%s"}' "$1" >&2
    exit 1
}

## Check for required commands
command -v jq >/dev/null 2>&1 || json_error "jq is not installed"
command -v aws >/dev/null 2>&1 || json_error "AWS CLI is not installed"

# Load JSON input using jq
input_data=$(cat)
env=$(echo "$input_data" | jq -r '.environment // empty')
bucket_name=$(echo "$input_data" | jq -r '.bucket_name // empty')
output_path=$(echo "$input_data" | jq -r '.output_path // empty')

# Validate required inputs
[ -z "$env" ] && json_error "environment variable is not set"
[ -z "$bucket_name" ] && json_error "bucket_name variable is not set"
[ -z "$output_path" ] && json_error "output_path variable is not set"

# Create temporary directory
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT

# Redirect all debug output to stderr
{
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    backend_folder="$(dirname "$script_dir")/backend"
    
    [ -d "$backend_folder" ] || json_error "No 'backend' folder found"
    
    cp -r "$backend_folder" "$temp_dir/backend"
    
    cd "$temp_dir/backend" || json_error "Failed to change to backend directory"
    python -m pip install --upgrade poetry >/dev/null 2>&1
    poetry install || (poetry lock && poetry install)
    chmod +x ./export-deps.sh
    ./export-deps.sh
    pip install -r requirements.txt >/dev/null 2>&1
    
    cd "$temp_dir" || json_error "Failed to change to temporary directory"
    zip -r "$output_path" backend -x \*.tf \*sonar-project.properties \*backend-build.sh \*.terraform* \*dev* >/dev/null 2>&1
    
    aws s3 cp "$output_path" "s3://$bucket_name/tt_backend.zip" \
        --metadata "environment=$env" >/dev/null 2>&1
    
    version_id=$(aws s3api head-object \
        --bucket "$bucket_name" \
        --key "tt_backend.zip" \
        --query 'VersionId' \
        --output text 2>/dev/null)
    
    packaged_files=($(find "$temp_dir/backend" -type f -printf "%P\n"))
    packaged_files_string=$(printf '%s,' "${packaged_files[@]}" | sed 's/,$//')
    
    # Final JSON output
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
} >&2
