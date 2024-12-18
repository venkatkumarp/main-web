#!/usr/bin/env python3

import subprocess
import sys
import json
import os

def run_command(cmd, check=True, capture_output=False):
    """
    Run a command with error handling and optional output capture.
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
        # Capture error message and include it in the result
        return f"Command failed: {cmd}\nError: {e.stderr}"

def main():
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
        run_command([venv_python, "-m", "poetry", "install"])

        # Ensure export script is executable
        run_command(["chmod", "+x", "./export-deps.sh"])

        # Run export script
        export_result = run_command(["./export-deps.sh"], capture_output=True)

        if isinstance(export_result, str) and export_result.startswith("Command failed"):
            raise RuntimeError(export_result)

        # Create backend zip
        zip_result = run_command(["zip", "-r", output_path, "."])

        # Upload to S3
        upload_result = run_command([
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
        # Handle exceptions and capture error details
        result = {
            "status": "failure",
            "message": str(e),
            "output_path": "",
            "bucket_name": ""
        }

    # Print only JSON output to ensure Terraform can process it
    print(json.dumps(result))

if __name__ == "__main__":
    sys.exit(main())
