# Automate Sqoop Jobs Migration from On-premise to Elastic MapReduce

***

## Summary

There are many customers using on-premise Hadoop environments with Sqoop ingestion to compound the raw layer and they hope to migrate to AWS Cloud using lift and shift strategy. This pattern presents how to migrate Sqoop codes to AWS EMR and provide a security layer with reusable artifacts. Based in previous customers experiences, it was defined a flow using on-premise Sqoop options files and convert them with best practices of: security, agility and speed to guarantee a fast adoption of AWS Cloud. This conversion process suggests an ingestion flow using shell scripts commands and supports conversions of files with eval, import and export Sqoop commands.


## Prerequisites

- An active AWS account
- Network: Create the communication between source database and AWS environment. Make sure all the network resources are configured correctly on AWS: VPC, Subnet, Network ACL, Security Group 
- IAM Permissions: Make sure that all permissions (IAM roles) are applied to execute Cloudformation. You must have access to create S3 bucket, Lambda function and EMR cluster.


## Limitations 

This solution is able to convert around 500 script file at the same time. If you need to convert more than it, please execute in parts. 

## Code

This repository includes the following codes:
- sqoop-to-emr.yml - responsible to create all resources for this solution
- hadoop-vault.py - python code responsible to integrate the secret manager and EMR
- bootstrap.sh - all the dependencies required to EMR
- mapping_file_example - file with all information to change content on sqoop scripts
- sqoop-test.py - python code with method to execute sqoop scripts

## Instructions

### Set up the Artifacts S3 bucket
On the Amazon S3 console, choose or create an S3 bucket to host the jars, bootstrap.sh and hadoop-vault.py. This S3 bucket must be in the same AWS Region as the Amazon EMR cluster you want to create. An Amazon S3 bucket name is globally unique, and the namespace is shared by all AWS accounts. The S3 bucket name cannot include leading slashes.

### Upload Configuration Files
- Upload Jar Files: A JAR (Java ARchive) file is a collection of Java classes in a zip file format. They are responsible to integrate Sqoop application and datasource. Make sure to copy all Jar files before to execute CFN stack. Upload your sqoop scripts into the bucket previously defined. As suggestion, you may define a path <YOUR_ARTIFACT_BUCKET>/jars
- Upload bootstrap file: A bootstrap shell file is executed when an EMR cluster is created. With the bootstrap, it’s possible to install packages into EMR, download files and transfer files from S3 to EMR file system. As suggestion, you may define a path <YOUR_ARTIFACT_BUCKET>/bootstrap and obtain the code on the repository
- Upload hadoop vault file: This hadoop vault python file gets the credencials from the Secrets Manager secret and create a hadoop credencial with the source database password. This step is executed automatically after EMR is deployed. As suggestion, you may define a path <YOUR_ARTIFACT_BUCKET>/hadoop-vault and obtain the code on the repository: hadoop-vault.py

### Create Mapping File
#### Create Insert Session
Insert session is responsible to include new parameters in Sqoop File at the conversion moment.

It's recommended to include both parameters in the insert section to guarantee the integration between secret manager and hadoop key vault in EMR cluster: 
- "--password-alias your_secret_name"
- "-Dhadoop.security.credential.provider.path=jceks://hdfs/tmp/your_secret_name.jceks"

#### Create Replace Session
Replace session is responsible to change contents in Sqoop File at the conversion moment.

- reserved sqoop commands: before “?"
- string to be find and replaced:  before "::"
- string to be considered: after "::" 

All parameters in this section will be used as string to replace in Sqoop scripts.


### Deploy the AWS CloudFormation Template
Open the AWS CloudFormation console in the same AWS Region as your S3 bucket and deploy the template. 
When you launch the template, you'll be prompted for the following information:
- InstanceType: define your EMR instance type. The default is m5.xlarge, but you can choose other.
- S3Bootstrap: define the full path of custom EMR bootstrap following this example s3://YOUR_ARTIFACT_BUCKET/bootstrap/bootstrap.sh (please use the bootstrap available on the repository).
- S3Jars: S3 path for the folder containing the jars, for example: s3://YOUR_ARTIFACT_BUCKET/jars/
- S3Vault: S3 path where hadoop vault script is stored (please use the hadoop-vault available on the repository). For example: s3://YOUR_ARTIFACT_BUCKET/hadoop-vault/hadoop-vault.py
- S3VaultFile: hadoop vault script name. The default name is hadoop-vault.py
- SecretName: name of the secret for the database
- DBUsername: username of database (minLength 1 and maxlength 16). These parameter will be applied in Secret Manager 
- DBPassword: password for the database (minLength 1 and maxlength 40). These parameter will be applied in Secret Manager 
- ReleaseEMR: choose your EMR release, the Default is emr-6.6.0, but you can choose other.
- CoreInstanceQtt: Quantity of core instances on EMR. The Default value is 1
- TaskInstanceQtt: Quantity of task instances on EMR. The Default value is 1
- S3BucketPathSource: path where the sqoop scripts will be uploaded on the new S3 bucket created by CTF. For example: source/
- S3BucketPathMapping: path where the mapping file will be uploaded on the new S3 bucket created by CTF. For example: mapping/mapping_file.txt


### Upload files for conversion
- Upload mapping file: Upload your mapping file into the bucket created by CloudFormation template. Please use the path you chose in the previous step. 
- Upload OnPremise Sqoop Scripts: Upload your on-premise Sqoop scripts into the bucket created by CloudFormation template. Please use the path you chose in the previous step. 


### Check the converted sqoop files
Check your converted Sqoop files on the path BUCKET_NAME/target

### Test your new Sqoop Script
After the stack is created on CloudFormation and the files are uploaded in S3, it’s time to validate your Sqoop script on EMR.

Go to EMR, connect in MASTER instance (SSH or Session Manager) and execute the following commands.

- First, it’s necessary to copy the files to EMR with the command:

`sudo aws s3 cp s3://<BUCKET_NAME>/target/ . —recursive`

- Execute the python code changing the parameters:
1. your_region: the region where you deployed your stack
2. your_secret_name: your secret name

