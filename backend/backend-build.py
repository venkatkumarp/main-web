#!/usr/bin/env python3

import subprocess
import sys
import json
import os
import venv

def create_virtual_environment():
    """
    Create a virtual environment if it doesn't exist
    """
    venv_path = ".venv"
    if not os.path.exists(venv_path):
        venv.create(venv_path, with_pip=True)
    return venv_path

def run_command(cmd, capture_output=False):
    """
    Run a command with error handling
    """
    try:
        if capture_output:
            return subprocess.run(cmd, check=True, capture_output=True, text=True)
        else:
            return subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Command failed: {cmd}")
        print(f"Error output: {e.stderr}")
        raise

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

        # Create virtual environment
        venv_path = create_virtual_environment()

        # Activate virtual environment and set up Poetry
        poetry_env_cmd = [
            f"{venv_path}/bin/python", "-m", "pip", "install", 
            "--upgrade", "poetry"
        ]
        run_command(poetry_env_cmd)

        # Verify Poetry installation
        poetry_path = f"{venv_path}/bin/poetry"
        run_command([poetry_path, "--version"])

        # Install project dependencies
        run_command([poetry_path, "install"])

        # Verify export-deps.sh exists and is executable
        if not os.path.exists("./export-deps.sh"):
            raise FileNotFoundError("export-deps.sh script not found")
        
        # Make sure the script is executable
        run_command(["chmod", "+x", "./export-deps.sh"])

        # Run export-deps.sh with verbose output
        export_output = run_command(["./export-deps.sh"], capture_output=True)
        print("Export dependencies output:", export_output.stdout)

        # Zip the backend
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
        # Capture detailed error information
        result = {
            "status": "failure",
            "message": str(e),
            "output_path": "",
            "bucket_name": ""
        }

    # Ensure only JSON is printed
    print(json.dumps(result))

if __name__ == "__main__":
    main()
