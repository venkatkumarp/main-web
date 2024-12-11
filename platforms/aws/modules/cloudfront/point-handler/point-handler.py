### Import Section ###
from __future__ import print_function
import boto3
import os
import logging
from urllib.parse import quote

### Logger ###
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)
 
 
def point_handler(event, context):
    del event, context

    base_uri = os.environ.get('base_url', "https://login.microsoftonline.com")

   
    tenant_id = "fcb2b37b-5da0-466b-9b83-0014b67a7c78"
    client_id = ""
    redirect_uri = "https://cv7msci6c2.execute-api.eu-central-1.amazonaws.com/qa/access-token?Authorization=abc"
    code_challenge = ""

    redirect_uri = quote(redirect_uri)

    # Construct the Auth string
    scope = "openid+profile+email+User.read+offline_access"
    response_type = "code%20id_token"
    response_mode = "form_post"
    code_challenge_method = "plain"
    state = "08db2007-077b-4fa5-b779-f703d1913db6"
    auth_uri = "oauth2/v2.0/authorize"
    nonce="GjHcUkMBpdVHZQrFvFeLKI"    
 
    authentication_endpoint = "{}/{}/{}?client_id={}&redirect_uri={}&scope={}&response_type={}&response_mode={}&code_challenge_method={}&code_challenge={}&state={}&nonce={}".format(base_uri,tenant_id,auth_uri,client_id,redirect_uri,scope,response_type,response_mode,code_challenge_method,code_challenge,state,nonce)
 
    logger.info("Auth URL: {}".format(authentication_endpoint))
 
    response = {
        'status': '302',
        'statusDescription': 'Found',
        'headers': {
            'location': [{
                'key': 'Location',
                'value': authentication_endpoint
            }]
        }
    }
 
    return response
