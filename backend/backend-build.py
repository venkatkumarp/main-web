#!/usr/bin/env python3

import subprocess
import sys
import json
import os
import shutil

def main():
    # Read input from Terraform
    input_data = json.load(sys.stdin)
    environment = input_data.get("environment")
    bucket_name = input_data.get("bucket_name")
    output_path = input_data.get("output_path")

    # Ensure Poetry is installed
    try:
        subprocess.run(["python3", "-m", "pip", "install", "--upgrade", "poetry"], shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error installing poetry: {str(e)}")
        sys.exit(1)

    # Execute the commands
    try:
        subprocess.run(["poetry", "install"], shell=True, check=True)
        subprocess.run(["chmod", "+x", "./export-deps.sh"], shell=True, check=True)
        subprocess.run(["./export-deps.sh"], shell=True, check=True)
        subprocess.run(["pip", "install", "-r", "requirements.txt"], shell=True, check=True)

        # Get the path to site-packages in the virtual environment
        venv_site_packages = subprocess.check_output(
            ["python3", "-c", "import site; print(site.getsitepackages()[0])"], 
            universal_newlines=True
        ).strip() + "/site-packages"

        # Create a directory to store the backend build (excluding venv)
        build_dir = "build"
        if os.path.exists(build_dir):
            shutil.rmtree(build_dir)
        os.makedirs(build_dir)

        # Copy site-packages into the build directory
        if os.path.exists(venv_site_packages):
            shutil.copytree(venv_site_packages, os.path.join(build_dir, "site-packages"))

        # Now copy the backend contents, excluding venv directory
        subprocess.run(["rsync", "-av", "--exclude", "venv", ".", build_dir], shell=True, check=True)

        # Zip the contents of the backend excluding venv
        subprocess.run(["zip", "-r", output_path, ".", "-x", "venv/*"], shell=True, check=True)

        # Upload the zip file to S3 using AWS CLI
        subprocess.run(["aws", "s3", "cp", output_path, f"s3://{bucket_name}/backend.zip"], shell=True, check=True)

        # Return result to Terraform
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

    # Return result as JSON
    print(json.dumps(result))

if __name__ == "__main__":
    main()
