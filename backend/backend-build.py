#!/usr/bin/env python3

import subprocess
import sys
import json
import os

def create_virtualenv(venv_path):
    # Create a virtual environment if it doesn't exist
    if not os.path.exists(venv_path):
        subprocess.run([sys.executable, "-m", "venv", venv_path], check=True)

def activate_virtualenv(venv_path):
    # Activate the virtual environment and return the activation script path
    if os.name == 'posix':  # For Linux/macOS
        return os.path.join(venv_path, 'bin', 'activate')
    else:  # For Windows
        return os.path.join(venv_path, 'Scripts', 'activate')

def install_poetry(venv_path):
    # Install Poetry inside the virtual environment
    activate_script = activate_virtualenv(venv_path)
    subprocess.run(f"source {activate_script} && python -m pip install --upgrade poetry", shell=True, check=True)

def main():
    # Read input from Terraform
    input_data = json.load(sys.stdin)
    environment = input_data.get("environment")
    bucket_name = input_data.get("bucket_name")
    output_path = input_data.get("output_path")

    result = {}

    try:
        # Set up virtual environment
        venv_path = "./venv"
        create_virtualenv(venv_path)
        
        # Activate the virtual environment and install Poetry
        install_poetry(venv_path)

        # Use the virtual environment to run all subsequent commands
        activate_script = activate_virtualenv(venv_path)

        # Upgrade Poetry if necessary (within venv)
        subprocess.run(f"source {activate_script} && python -m pip install --upgrade poetry", shell=True, check=True)

        # Try to install dependencies with poetry (within venv)
        try:
            subprocess.run(f"source {activate_script} && poetry install", shell=True, check=True)
        except subprocess.CalledProcessError:
            # Fallback if poetry install fails (within venv)
            subprocess.run(f"source {activate_script} && poetry lock", shell=True, check=True)
            subprocess.run(f"source {activate_script} && poetry install", shell=True, check=True)

        # Make the shell script executable and run it (within venv)
        subprocess.run(f"source {activate_script} && chmod +x ./export-deps.sh", shell=True, check=True)
        subprocess.run(f"source {activate_script} && ./export-deps.sh", shell=True, check=True)

        # Install other dependencies from requirements.txt (within venv)
        subprocess.run(f"source {activate_script} && pip install -r requirements.txt", shell=True, check=True)

        # Zip the backend folder
        subprocess.run(f"source {activate_script} && zip -r {output_path} .", shell=True, check=True)

        # Upload the zip file to S3 using AWS CLI (using system-wide aws cli)
        subprocess.run(f"aws s3 cp {output_path} s3://{bucket_name}/backend.zip", shell=True, check=True)

        # Populate the result dictionary
        result = {
            "output_path": output_path,
            "bucket_name": bucket_name,
            "status": "success",
            "message": "Backend packaging and upload successful"
        }

    except subprocess.CalledProcessError as e:
        # Handle errors in the subprocess and return failure status
        result = {
            "status": "failure",
            "message": f"Error: {str(e)}"
        }

    # Return result as a valid JSON object to Terraform
    print(json.dumps(result))

if __name__ == "__main__":
    main()
