#!/bin/bash
#----------------------------------------------------------------
# Contain properties and checks specific to AWS EKS
#----------------------------------------------------------------

: ${EKS_VPC_TEMPLATE:="https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-02-11/amazon-eks-vpc-sample.yaml"}

: ${EKS_NODE_INSTANCETYPE:="t3.small"}
: ${EKS_NODE_INITIALCOUNT:="3"}

: ${EKS_NODE_GRP_TEMPLATE:="https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-02-11/amazon-eks-nodegroup.yaml"}

if [ -z "$(which aws)" ]; then
  echo "This script requires the aws cli"
  echo "Please install it via one of the methods described here:"
  echo "https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html"
  exit 1
fi

if [ -z "$(which aws-iam-authenticator)" ]; then
  echo "This script requires the aws-iam-authenticator utility"
  echo "Please install it via one of the methods described here:"
  echo "https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html"
  exit 1
fi
