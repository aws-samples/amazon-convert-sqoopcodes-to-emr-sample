#!/bin/bash

#SM Agent
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo status amazon-ssm-agent >>/tmp/ssm-status.log


bucket_path_jdbc=$1
bucket_path_vault=$2

sudo mkdir -p /home/hadoop
sudo mkdir -p /usr/lib/spark/jars
sudo mkdir -p /usr/lib/hadoop/lib
sudo mkdir -p /usr/lib/sqoop/lib


#JDBC Agents
sudo aws s3 cp $bucket_path_jdbc /home/hadoop/ --recursive
sudo chmod -R 777 /home/hadoop/*.jar
sudo cp /home/hadoop/*.jar /usr/lib/spark/jars/
sudo cp /home/hadoop/*.jar /usr/lib/hadoop/lib/
sudo cp /home/hadoop/*.jar /usr/lib/sqoop/lib/

sudo python3 -m pip install boto3


#hadoop vault
sudo aws s3 cp $bucket_path_vault /home/hadoop/

sudo file_name=`echo ${bucket_path_vault##*\/}`

sudo chmod 777 /home/hadoop/$file_name

