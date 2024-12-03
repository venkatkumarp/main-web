import json

def lambda_handler(event, context):
    resource = event["methodArn"]
    print(resource)
    response = '''{
                "principalId": "user",
                "policyDocument": {
                    "Version": "2012-10-17",
                    "Statement": [
                    {
                        "Action": "execute-api:Invoke",
                        "Effect": "Allow",
                        "Resource": "arn:aws:execute-api:eu-central-1:590183961751:ht2xz51fgk/*/*"
                    }
                    ]
                }
                }'''
    response_json = json.loads(response)
    print(response)
    return response_json
    
    
    
    
    
    
