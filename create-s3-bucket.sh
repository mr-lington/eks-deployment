#!/bin/bash

# set variable for bucket-name
BUCKET_NAME="eks-statefile-bucket1"
AWS_REGION="eu-west-3"
AWS_PROFILE="Lington"



# create bucket
aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" \
  --create-bucket-configuration LocationConstraint="$AWS_REGION"

# enable versioning
aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --region "$AWS_REGION" --profile "$AWS_PROFILE" \
  --versioning-configuration Status=Enabled

echo "Creating Cluster"
cd netwoking
terraform init
terraform fmt 
terraform validate
terraform apply -auto-approve