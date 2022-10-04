import boto3
import os
import json

sm_client = boto3.client("secretsmanager", region_name="<your region>")

get_secret_value_response = sm_client.get_secret_value(SecretId="<your secret name>")
secret = get_secret_value_response['SecretString']

secret = json.loads(secret)
db_username = secret.get('username')

os.system(f"sh sqoop_file.sh {db_username}")