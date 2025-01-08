import boto3
from botocore.exceptions import ClientError
import json
import msal


def get_secret():
    secret_name = "journyx-secret-scope-dev"
    region_name = "eu-central-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    # secret = get_secret_value_response['SecretString']
    return json.loads(get_secret_value_response['SecretString'])


def get_secret_cwiddb():
    secret_name = "cwid_db_credentials"
    region_name = "eu-central-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    # secret = get_secret_value_response['SecretString']
    return json.loads(get_secret_value_response['SecretString'])


def get_secret_client():
    secret_name = "/tt/dev/web-secrets"
    region_name = "eu-central-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    # secret = get_secret_value_response['SecretString']
    return json.loads(get_secret_value_response['SecretString'])


def generate_token():
    client_id = get_secret_client().get('clientID')
    client_secret = get_secret_client().get('client_secret')
    authority = 'https://login.microsoftonline.com/fcb2b37b-5da0-466b-9b83-0014b67a7c78'
    scope = ['https://graph.microsoft.com/.default']
    client = msal.ConfidentialClientApplication(client_id, authority=authority, client_credential=client_secret)
    token_result = client.acquire_token_silent(scope, account=None)
    if token_result:
        access_token = "Bearer " + token_result['access_token']
    if not token_result:
        token_result = client.acquire_token_for_client(scopes=scope)
        access_token = "Bearer " + token_result['access_token']

    return access_token
