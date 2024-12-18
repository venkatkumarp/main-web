#!/usr/bin/env python3

import subprocess
import sys
import json
import os

def main():
    # Read input from Terraform
    input_data = json.load(sys.stdin)
    environment = input_data.get("environment")
    bucket_name = input_data.get("bucket_name")
    output_path = input_data.get("output_path")

    result = {}

    try:
        # Upgrade Poetry if necessary
        subprocess.run(["python", "-m", "pip", "install", "--upgrade", "poetry"], shell=True, check=True)

        # Try to install dependencies with poetry
        try:
            subprocess.run(["poetry", "install"], shell=True, check=True)
        except subprocess.CalledProcessError:
            # Fallback if poetry install fails
            subprocess.run(["poetry", "lock"], shell=True, check=True)
            subprocess.run(["poetry", "install"], shell=True, check=True)

        # Make the shell script executable and run it
        subprocess.run(["chmod", "+x", "./export-deps.sh"], shell=True, check=True)
        subprocess.run(["./export-deps.sh"], shell=True, check=True)

        # Install other dependencies from requirements.txt
        subprocess.run(["pip", "install", "-r", "requirements.txt"], shell=True, check=True)

        # Zip the backend folder
        subprocess.run(["zip", "-r", output_path, "."], shell=True, check=True)

        # Upload the zip file to S3 using AWS CLI
        subprocess.run(["aws", "s3", "cp", output_path, f"s3://{bucket_name}/backend.zip"], shell=True, check=True)

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
