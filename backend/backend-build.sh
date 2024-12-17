#!/bin/bash
set -euo pipefail

# Redirect all debugging output to a file
exec 2>/tmp/backend-build-debug.log

# Function to log debug information
debug_log() {
    echo "[DEBUG] $1" >&2
}

# Strict error handling function
error_exit() {
    debug_log "ERROR: $1"
    jq -n --arg error "$1" '{"error": $error}' >&2
    exit 1
}

debug_log "Script started"

# Validate required commands
for cmd in jq aws python poetry zip; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        error_exit "$cmd is not installed"
    fi
done

debug_log "Commands validated"

# Read input data
input_data=$(cat)
debug_log "Input data: $input_data"

# Parse input using jq with error handling
env=$(echo "$input_data" | jq -r '.environment // empty') || error_exit "Failed to parse environment"
bucket_name=$(echo "$input_data" | jq -r '.bucket_name // empty') || error_exit "Failed to parse bucket_name"
output_path=$(echo "$input_data" | jq -r '.output_path // empty') || error_exit "Failed to parse output_path"

debug_log "Parsed inputs: env=$env, bucket=$bucket_name, output_path=$output_path"

# Validate inputs
[ -z "$env" ] && error_exit "Environment is not set"
[ -z "$bucket_name" ] && error_exit "Bucket name is not set"
[ -z "$output_path" ] && error_exit "Output path is not set"

# Create temporary directory
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
debug_log "Temporary directory: $temp_dir"

# Get script and backend directories
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backend_folder="$(dirname "$script_dir")/backend"

debug_log "Script directory: $script_dir"
debug_log "Backend folder: $backend_folder"

# Validate backend folder exists
[ ! -d "$backend_folder" ] && error_exit "Backend folder not found"

# Execute all operations with error tracing
{
    debug_log "Copying backend folder"
    cp -r "$backend_folder" "$temp_dir/backend"

    debug_log "Changing to backend directory"
    cd "$temp_dir/backend" || error_exit "Failed to change to backend directory"

    debug_log "Installing dependencies"
    python -m pip install --upgrade poetry
    poetry install || (poetry lock && poetry install)

    debug_log "Exporting dependencies"
    chmod +x ./export-deps.sh
    ./export-deps.sh
    pip install -r requirements.txt

    debug_log "Creating ZIP file"
    cd "$temp_dir" || error_exit "Failed to change to temp directory"
    zip -r "$output_path" backend -x \*.tf \*sonar-project.properties \*backend-build.sh \*.terraform* \*dev* || error_exit "ZIP creation failed"

    debug_log "Uploading to S3"
    aws s3 cp "$output_path" "s3://$bucket_name/tt_backend.zip" \
        --metadata "environment=$env" || error_exit "S3 upload failed"

    debug_log "Retrieving version ID"
    version_id=$(aws s3api head-object \
        --bucket "$bucket_name" \
        --key "tt_backend.zip" \
        --query 'VersionId' \
        --output text) || error_exit "Failed to get version ID"

    debug_log "Getting packaged files"
    packaged_files=($(find "$temp_dir/backend" -type f -printf "%P\n"))
    packaged_files_string=$(printf '%s,' "${packaged_files[@]}" | sed 's/,$//')

    debug_log "Generating output JSON"
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

} >&2 # Redirect all output to stderr to prevent any stdout interference

debug_log "Script completed successfully"
