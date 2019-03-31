#!/bin/bash

AWS_REGION=us-west-2
EKS_IAMROLE_NAME=eksServiceRole2
aws cloudformation create-stack --region ${AWS_REGION} --stack-name ${EKS_IAMROLE_NAME} --template-body file://eks-iam-role.yml \
  --capabilities CAPABILITY_IAM 

echo ... waiting for role to be created
aws cloudformation wait stack-create-complete --region=${AWS_REGION} --stack-name ${EKS_IAMROLE_NAME}

aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${EKS_IAMROLE_NAME} 
AWS_SEC_GRP=$(aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${EKS_IAMROLE_NAME} | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="RoleArn").OutputValue')
romecho $AWS_SEC_GRP
