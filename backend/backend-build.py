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

    try:
        # Ensure Poetry is installed globally (if not, install it)
        try:
            subprocess.run(["poetry", "--version"], shell=True, check=True)
        except subprocess.CalledProcessError:
            print("Poetry not found. Installing Poetry...")
            subprocess.run(["python3", "-m", "pip", "install", "--user", "poetry"], shell=True, check=True)

        # Install dependencies using Poetry globally
        subprocess.run(["poetry", "install"], shell=True, check=True)

        # Ensure the shell script is executable and run it
        subprocess.run(["chmod", "+x", "./export-deps.sh"], shell=True, check=True)
        subprocess.run(["./export-deps.sh"], shell=True, check=True)

        # Install other dependencies from requirements.txt globally
        subprocess.run(["pip", "install", "-r", "requirements.txt"], shell=True, check=True)

        # Get global site-packages directory (system-wide packages)
        global_site_packages = subprocess.check_output(
            ["python3", "-c", "import site; print(site.getsitepackages()[0])"],
            universal_newlines=True
        ).strip() + "/site-packages"

        # Create a build directory to store the packaged backend contents
        build_dir = "build"
        if os.path.exists(build_dir):
            shutil.rmtree(build_dir)
        os.makedirs(build_dir)

        # Copy global site-packages to the build directory
        if os.path.exists(global_site_packages):
            shutil.copytree(global_site_packages, os.path.join(build_dir, "site-packages"))

        # Copy other backend files, excluding the venv directory
        subprocess.run(["rsync", "-av", "--exclude", "venv", ".", build_dir], shell=True, check=True)

        # Zip the contents of the backend, excluding venv
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

    # Ensure the result is valid JSON
    try:
        print(json.dumps(result))
    except Exception as json_error:
        print(f"JSON encoding failed: {str(json_error)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
