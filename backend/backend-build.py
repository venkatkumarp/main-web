#!/usr/bin/env python3

import subprocess
import sys
import json
import os
import traceback

def run_command(cmd, check=True, capture_output=False):
    """
    Run a command with error handling
    """
    try:
        result = subprocess.run(
            cmd, 
            check=check, 
            capture_output=capture_output, 
            text=True
        )
        return result
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Command failed: {cmd}\nError: {e.stderr}")

def main():
    # Prepare a default result dictionary
    result = {
        "status": "failure",
        "message": "Unknown error",
        "output_path": "",
        "bucket_name": ""
    }

    try:
        # Read input from Terraform
        input_data = json.load(sys.stdin)
        environment = input_data.get("environment", "")
        bucket_name = input_data.get("bucket_name", "")
        output_path = input_data.get("output_path", "backend.zip")

        # Ensure virtual environment exists
        if not os.path.exists(".venv"):
            run_command(["python3", "-m", "venv", ".venv"])

        # Activate virtual environment and install dependencies
        venv_python = ".venv/bin/python"
        venv_pip = ".venv/bin/pip"

        # Install Poetry
        run_command([venv_pip, "install", "--upgrade", "poetry"])

        # Install project dependencies
        run_command([".venv/bin/poetry", "install"])

        # Ensure export script is executable
        run_command(["chmod", "+x", "./export-deps.sh"])

        # Run export script
        run_command(["./export-deps.sh"])

        # Create backend zip
        run_command(["zip", "-r", output_path, "."])

        # Upload to S3
        run_command([
            "aws", "s3", "cp", 
            output_path, 
            f"s3://{bucket_name}/backend.zip"
        ])

        # Success result
        result = {
            "status": "success",
            "message": "Backend packaging and upload successful",
            "output_path": output_path,
            "bucket_name": bucket_name
        }

    except Exception as e:
        # Capture error details
        result = {
            "status": "failure",
            "message": str(e),
            "output_path": "",
            "bucket_name": ""
        }

    # Ensure the result is printed in proper JSON format
    print(json.dumps(result))

if __name__ == "__main__":
    sys.exit(main())
