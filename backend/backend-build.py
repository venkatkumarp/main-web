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

def activate_virtual_environment(venv_path):
    """
    Activate the virtual environment
    """
    activate_this = os.path.join(venv_path, 'bin', 'activate_this.py')
    
    try:
        exec(open(activate_this).read(), {'__file__': activate_this})
    except FileNotFoundError:
        # Fallback for Windows
        activate_this = os.path.join(venv_path, 'Scripts', 'activate_this.py')
        if os.path.exists(activate_this):
            exec(open(activate_this).read(), {'__file__': activate_this})

def main():
    # Initialize result dictionary with default failure state
    result = {
        "status": "failure",
        "message": "Unknown error occurred",
        "output_path": "",
        "bucket_name": "",
    }

    try:
        # Read input from Terraform
        input_data = json.load(sys.stdin)
        environment = input_data.get("environment", "")
        bucket_name = input_data.get("bucket_name", "")
        output_path = input_data.get("output_path", "backend.zip")

        # Create and activate virtual environment
        venv_path = create_virtual_environment()
        activate_virtual_environment(venv_path)

        # Full paths to executables in virtual environment
        pip_path = os.path.join(venv_path, 'bin', 'pip')
        poetry_path = os.path.join(venv_path, 'bin', 'poetry')

        # Suppress all print outputs
        with open(os.devnull, 'w') as devnull:
            # Install Poetry
            subprocess.run([pip_path, 'install', 'poetry'], 
                           stdout=devnull, stderr=devnull, check=True)

            # Poetry install commands
            subprocess.run([poetry_path, 'lock'], 
                           stdout=devnull, stderr=devnull, check=True)
            subprocess.run([poetry_path, 'install'], 
                           stdout=devnull, stderr=devnull, check=True)

            # Make export script executable
            subprocess.run(['chmod', '+x', './export-deps.sh'], check=True)
            subprocess.run(['./export-deps.sh'], check=True)

            # Install requirements
            subprocess.run([pip_path, 'install', '-r', 'requirements.txt'], 
                           stdout=devnull, stderr=devnull, check=True)

            # Zip backend
            subprocess.run(['zip', '-r', output_path, '.'], check=True)

            # Upload to S3
            subprocess.run(['aws', 's3', 'cp', output_path, 
                            f's3://{bucket_name}/backend.zip'], check=True)

        # Update result on success
        result = {
            "status": "success",
            "message": "Backend packaging and upload successful",
            "output_path": output_path,
            "bucket_name": bucket_name
        }

    except Exception as e:
        # Capture any errors
        result = {
            "status": "failure",
            "message": str(e),
            "output_path": "",
            "bucket_name": ""
        }

    # Ensure only JSON is printed
    sys.stderr = open(os.devnull, 'w')
    print(json.dumps(result))

if __name__ == "__main__":
    main()
