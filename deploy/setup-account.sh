#!/bin/bash

set -x

if [ -z "$1" ]; then
  echo "No environment selected, valid arguments are: QAL, UAT, STG and PRD."
  exit 1
fi

AWS_ENV_NAME=$1
AWS_ENV_NAME_LOWERCASE=`echo $1 | tr '[:upper:]' '[:lower:]:'`
AWS_ACCOUNT_ID=`aws sts get-caller-identity --query Account --output text --profile imb-$1`
AWS_DEFAULT_REGION=`aws configure get region`
PROJECT_NAME="magento-quickstart"
S3_BUCKET_NAME="${AWS_ENV_NAME_LOWERCASE}-${PROJECT_NAME}-${AWS_ACCOUNT_ID}"
SSH_KEY_NAME="${AWS_ENV_NAME}-${PROJECT_NAME}"

if [ ! -f ../parameters/parameters-imb-${AWS_ENV_NAME}.json ]; then
  echo "Please create a parameters file first."
  exit 1
fi

# Create S3 bucket
aws s3api create-bucket --bucket ${S3_BUCKET_NAME} --region ${AWS_DEFAULT_REGION} --create-bucket-configuration LocationConstraint=${AWS_DEFAULT_REGION} --profile imb-$1

# Copy templates and parameter file to S3 bucket
aws s3 cp ../cloudformation s3://${S3_BUCKET_NAME}/cloudformation/ --recursive --profile imb-$1
aws s3 cp ../parameters/parameters-imb-${AWS_ENV_NAME}.json s3://${S3_BUCKET_NAME}/cloudformation/parameters-imb-${AWS_ENV_NAME}.json --profile imb-$1

# Generate SSH key and copy private key to S3 bucket
aws ec2 create-key-pair --key-name ${SSH_KEY_NAME} --query 'KeyMaterial' --output text --region ${AWS_DEFAULT_REGION} > ${SSH_KEY_NAME}.pem --profile imb-$1
aws s3 cp ${SSH_KEY_NAME}.pem s3://${S3_BUCKET_NAME}/devops/${SSH_KEY_NAME}.pem --profile imb-$1
rm -f ${SSH_KEY_NAME}.pem
