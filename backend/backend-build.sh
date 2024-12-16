#!/bin/bash
set -euo pipefail

# Comprehensive logging and error handling
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Enhanced JSON-safe error handling
error_exit() {
    local error_message="$1"
    
    # Log the error
    log "ERROR: $error_message"
    
    # Escape the error message for JSON
    escaped_error=$(printf '%s' "$error_message" | jq -R -s '.')
   
    # Output error as JSON to stderr
    printf '{"status": "error", "message": %s, "timestamp": "%s"}\n' "$escaped_error" "$(date -u +"%Y-%m-%d %T")" >&2
   
    # Exit with error status
    exit 1
}

# Trap unexpected errors
trap 'error_exit "Unexpected error occurred at line $LINENO"' ERR

# Install Python with enhanced detection and installation
install_python() {
    log "Checking Python installation..."
    
    # Check for Python3
    if ! command -v python3 >/dev/null 2>&1; then
        log "Python3 not found. Attempting to install..."
        
        # Comprehensive package manager detection and installation
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip python3-venv
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y python3 python3-pip python3-virtualenv
        elif command -v brew >/dev/null 2>&1; then
            brew install python
        elif command -v pkg >/dev/null 2>&1; then
            sudo pkg install -y python3
        else
            error_exit "Unable to install Python. No supported package manager found."
        fi
    fi

    # Verify Python installation
    python3 --version || error_exit "Python installation failed"

    # Ensure pip is installed and up to date
    python3 -m ensurepip --upgrade
    python3 -m pip install --upgrade pip setuptools wheel
}

# Install Poetry with comprehensive checks
install_poetry() {
    log "Checking Poetry installation..."
    
    # Ensure Python is installed first
    install_python

    # Install Poetry if not present
    if ! command -v poetry >/dev/null 2>&1; then
        log "Poetry not found. Attempting to install..."
        
        # Try multiple installation methods
        python3 -m pip install poetry || \
        curl -sSL https://install.python-poetry.org | python3 - || \
        error_exit "Failed to install Poetry"
    fi

    # Verify Poetry installation
    poetry --version || error_exit "Poetry verification failed"
}

# Install prerequisite tools
install_prerequisites() {
    log "Checking prerequisite tools..."
    
    # Ensure Python is installed first
    install_python

    # List of tools to check and install
    local tools=("jq" "aws" "zip" "curl")
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log "$tool not found. Attempting to install..."
            
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update
                sudo apt-get install -y "$tool"
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y "$tool"
            elif command -v brew >/dev/null 2>&1; then
                brew install "$tool"
            elif command -v pkg >/dev/null 2>&1; then
                sudo pkg install -y "$tool"
            else
                error_exit "$tool is not installed and cannot be automatically installed"
            fi
        fi
    done
}

# Prepare environment and run prerequisite installations
prepare_environment() {
    log "Preparing development environment..."
    
    # Run installations in specific order
    install_python
    install_prerequisites
    install_poetry

    # Final verification of critical tools
    command -v jq >/dev/null 2>&1 || error_exit "jq is not installed"
    command -v aws >/dev/null 2>&1 || error_exit "AWS CLI is not installed"
    command -v poetry >/dev/null 2>&1 || error_exit "Poetry is not installed"
    command -v python3 >/dev/null 2>&1 || error_exit "Python3 is not installed"
    command -v zip >/dev/null 2>&1 || error_exit "zip is not installed"
}

# Main script execution
main() {
    # Prepare environment
    prepare_environment

    # Read input from stdin with fallback
    input_data=$(cat || echo '{"environment":"default","bucket_name":"default-bucket","output_path":"/tmp/backend.zip"}')
    log "Input data received: $input_data"

    # Parse input using jq with error handling
    env=$(echo "$input_data" | jq -r '.environment // empty')
    bucket_name=$(echo "$input_data" | jq -r '.bucket_name // empty')
    output_path=$(echo "$input_data" | jq -r '.output_path // empty')

    # Validate required inputs
    [ -z "$env" ] && error_exit "environment variable is required"
    [ -z "$bucket_name" ] && error_exit "bucket_name variable is required"
    [ -z "$output_path" ] && error_exit "output_path variable is required"

    # Create temporary working directory
    temp_dir=$(mktemp -d) || error_exit "Failed to create temporary directory"
    trap 'rm -rf "$temp_dir"' EXIT

    # Determine script and backend folder locations
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    backend_folder="$(dirname "$script_dir")/backend"

    # Validate backend folder exists
    [ ! -d "$backend_folder" ] && error_exit "No 'backend' folder found"

    # Copy backend folder to temporary location
    cp -r "$backend_folder" "$temp_dir/backend" || error_exit "Failed to copy backend folder"

    # Change to backend directory
    cd "$temp_dir/backend" || error_exit "Failed to change to backend directory"

    # Comprehensive dependency management
    {
        log "Installing project dependencies..."
        
        # Upgrade pip and setuptools
        python3 -m pip install --upgrade pip setuptools

        # Create virtual environment
        python3 -m venv .venv
        source .venv/bin/activate

        # Install or update Poetry
        python3 -m pip install --upgrade poetry

        # Install project dependencies
        poetry config virtualenvs.create false
        poetry install || (poetry lock && poetry install)
        
        # Export dependencies if export script exists
        if [ -f ./export-deps.sh ]; then
            chmod +x ./export-deps.sh
            ./export-deps.sh
        fi
        
        # Install requirements as a fallback
        if [ -f requirements.txt ]; then
            pip install -r requirements.txt
        fi
    } || error_exit "Dependency installation failed"

    # Create ZIP package
    cd "$temp_dir" || error_exit "Failed to change to temporary directory"
    zip_output=$(zip -r "$output_path" backend \
        -x \*.tf \*sonar-project.properties \*backend-build.sh \*.terraform* \*dev* 2>&1) \
        || error_exit "ZIP creation failed: $zip_output"

    # Upload to S3 with metadata
    upload_output=$(aws s3 cp "$output_path" "s3://$bucket_name/tt_backend.zip" \
        --metadata "environment=$env" 2>&1) \
        || error_exit "S3 upload failed: $upload_output"

    # Retrieve version ID
    version_id=$(aws s3api head-object \
        --bucket "$bucket_name" \
        --key "tt_backend.zip" \
        --query 'VersionId' \
        --output text 2>/dev/null) \
        || error_exit "Failed to retrieve S3 object version ID"

    # Generate list of packaged files
    packaged_files=($(find "$temp_dir/backend" -type f -printf "%P\n"))
    packaged_files_string=$(printf '%s,' "${packaged_files[@]}" | sed 's/,$//')

    # Output clean JSON result
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
