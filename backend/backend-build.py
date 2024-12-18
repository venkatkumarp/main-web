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
    result = {
        "status": "failure",
        "message": "Unknown error",
        "output_path": "",
        "bucket_name": ""
    }

    try:
        # Read input from Terraform
        input_data = json.load(sys.stdin)
        environment = input_data.get("environment")
        bucket_name = input_data.get("bucket_name")
        output_path = input_data.get("output_path")

        # Ensure virtual environment exists
        venv_dir = ".venv"
        if not os.path.exists(venv_dir):
            print(f"Creating virtual environment at {venv_dir}")
            run_command(["python3", "-m", "venv", venv_dir])

        # Activate the virtual environment (note: use the appropriate path for your system)
        venv_python = os.path.join(venv_dir, "bin", "python")
        venv_pip = os.path.join(venv_dir, "bin", "pip")

        # Install Poetry in the virtual environment
        print("Installing poetry...")
        run_command([venv_pip, "install", "--upgrade", "poetry"])

        # Check if poetry was installed successfully (for debugging purposes)
        result = subprocess.run([venv_python, "-m", "poetry", "--version"], capture_output=True, text=True, shell=True)
        print("Poetry version:", result.stdout)  # Debugging output

        # Run poetry lock to update the lock file in case it's out of sync
        print("Updating poetry lock file...")
        run_command([venv_python, "-m", "poetry", "lock", "--no-update"])

        # Install project dependencies with poetry
        print("Running poetry install...")
        run_command([venv_python, "-m", "poetry", "install"])

        # Ensure export script is executable
        run_command(["chmod", "+x", "./export-deps.sh"])

        # Run export script
        run_command(["./export-deps.sh"])

        # Install additional requirements if needed
        run_command([venv_python, "-m", "pip", "install", "-r", "requirements.txt"])

        # Zip the backend folder
        run_command(["zip", "-r", output_path, "."], shell=True, check=True)

        # Upload to S3
        run_command([
            "aws", "s3", "cp", 
            output_path, 
            f"s3://{bucket_name}/backend.zip"
        ])

        result = {
            "output_path": output_path,
            "bucket_name": bucket_name,
            "status": "success",
            "message": "Backend packaging and upload successful"
        }

    except subprocess.CalledProcessError as e:
        result = {
            "status": "failure",
            "message": f"Error: {str(e)}"
        }

    # Print the result as JSON (required for Terraform)
    print(json.dumps(result))

if __name__ == "__main__":
    main()
