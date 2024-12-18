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
        print(f"Creating virtual environment in {venv_path}")
        venv.create(venv_path, with_pip=True)
    return venv_path

def activate_virtual_environment(venv_path):
    """
    Activate the virtual environment
    """
    # Construct paths for different operating systems
    activate_this = os.path.join(venv_path, 'bin', 'activate_this.py')
    
    # Try to activate the virtual environment
    try:
        exec(open(activate_this).read(), {'__file__': activate_this})
        print(f"Virtual environment activated from {activate_this}")
    except FileNotFoundError:
        # Fallback for Windows
        activate_this = os.path.join(venv_path, 'Scripts', 'activate_this.py')
        if os.path.exists(activate_this):
            exec(open(activate_this).read(), {'__file__': activate_this})
            print(f"Virtual environment activated from {activate_this}")
        else:
            print("Could not find virtual environment activation script")

def install_poetry(venv_path):
    """
    Install Poetry in the virtual environment
    """
    poetry_install_cmd = [
        os.path.join(venv_path, 'bin', 'pip'),
        'install',
        'poetry'
    ]
    
    try:
        subprocess.run(poetry_install_cmd, check=True)
        print("Poetry installed successfully")
    except subprocess.CalledProcessError as e:
        print(f"Failed to install Poetry: {e}")
        raise

def main():
    # Read input from Terraform
    input_data = json.load(sys.stdin)
    environment = input_data.get("environment")
    bucket_name = input_data.get("bucket_name")
    output_path = input_data.get("output_path")

    result = {}

    try:
        # Create and activate virtual environment
        venv_path = create_virtual_environment()
        activate_virtual_environment(venv_path)

        # Path to Poetry in virtual environment
        poetry_path = os.path.join(venv_path, 'bin', 'poetry')

        # Install Poetry
        install_poetry(venv_path)

        # Construct poetry commands using full path
        poetry_install_cmd = [poetry_path, 'install']
        poetry_lock_cmd = [poetry_path, 'lock']

        # Try to install dependencies
        try:
            subprocess.run(poetry_install_cmd, check=True)
        except subprocess.CalledProcessError:
            # Fallback: try to lock dependencies first
            subprocess.run(poetry_lock_cmd, check=True)
            subprocess.run(poetry_install_cmd, check=True)

        # Make the shell script executable and run it
        subprocess.run(["chmod", "+x", "./export-deps.sh"], check=True)
        subprocess.run(["./export-deps.sh"], check=True)

        # Install other dependencies from requirements.txt
        pip_path = os.path.join(venv_path, 'bin', 'pip')
        subprocess.run([pip_path, 'install', '-r', 'requirements.txt'], check=True)

        # Zip the backend folder
        subprocess.run(["zip", "-r", output_path, "."], check=True)

        # Upload the zip file to S3 using AWS CLI
        subprocess.run(["aws", "s3", "cp", output_path, f"s3://{bucket_name}/backend.zip"], check=True)

        # Populate the result dictionary
        result = {
            "output_path": output_path,
            "bucket_name": bucket_name,
            "status": "success",
            "message": "Backend packaging and upload successful"
        }

    except Exception as e:
        # Comprehensive error handling
        result = {
            "status": "failure",
            "message": f"Error: {str(e)}",
            "error_type": type(e).__name__
        }

    # Return result as a valid JSON object to Terraform
    print(json.dumps(result))

if __name__ == "__main__":
    main()
