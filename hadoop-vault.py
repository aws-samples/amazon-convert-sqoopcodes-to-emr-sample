import boto3
import sys
import os
import json

secret_name = sys.argv[1]

sm_client = boto3.client("secretsmanager", region_name="us-east-1")

get_secret_value_response = sm_client.get_secret_value(SecretId=secret_name)
secret = get_secret_value_response['SecretString']

secret = json.loads(secret)
db_password = secret.get('password')

os.system(f"hadoop credential create {secret_name} -provider jceks://hdfs/tmp/{secret_name}.jceks -value {db_password}")
