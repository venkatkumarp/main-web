import json
import os
import subprocess
import sys

# Function to handle script execution and return the JSON response
def execute():
    try:
        # Extract the arguments passed from Terraform
        environment = sys.argv[1]
        bucket_name = sys.argv[2]
        output_path = sys.argv[3]
        
        # Change directory to 'backend' folder
        os.chdir('backend')

        # Run the shell commands as per your original request
        subprocess.run(["python", "-m", "pip", "install", "--upgrade", "poetry"], check=True)
        subprocess.run(["poetry", "install"], check=True)
        subprocess.run(["chmod", "+x", "./export-deps.sh"], check=True)
        subprocess.run(["./export-deps.sh"], check=True)
        subprocess.run(["pip", "install", "-r", "requirements.txt"], check=True)

        # Zip the backend directory
        subprocess.run(["zip", "-r", output_path, "."], check=True)

        # Return the output path to Terraform
        return json.dumps({"output_path": output_path, "bucket_name": bucket_name})
    
    except Exception as e:
        # Handle errors and print error message to Terraform
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

# Call the function
if __name__ == "__main__":
    execute()
