import subprocess
import sys
import json

def main():
    # Read input from Terraform
    input_data = json.load(sys.stdin)
    environment = input_data.get("environment")
    bucket_name = input_data.get("bucket_name")
    output_path = input_data.get("output_path")

    # Execute the commands
    commands = [
        "python -m pip install --upgrade poetry",
        "poetry install || (poetry lock && poetry install)",
        "chmod +x ./export-deps.sh",
        "./export-deps.sh",
        "pip install -r requirements.txt",
        f"zip -r {output_path} .",
        f"aws s3 cp {output_path} s3://{bucket_name}/backend.zip"
    ]

    for command in commands:
        subprocess.run(command, shell=True, check=True)

    # Return output to Terraform
    result = {
        "output_path": output_path,
        "bucket_name": bucket_name
    }
    print(json.dumps(result))

if __name__ == "__main__":
    main()
