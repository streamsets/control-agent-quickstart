#!/bin/bash
#----------------------------------------------------------
# Contain variable and checks that are required for EKS environemnt setups
#----------------------------------------------------------

export PROVIDER_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export COMMON_DIR=`echo $(cd ${PROVIDER_DIR}/../common; pwd)`

: ${EKS_VPC_TEMPLATE:="https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-02-11/amazon-eks-vpc-sample.yaml"}
export EKS_VPC_TEMPLATE

: ${EKS_NODE_INSTANCETYPE:="t3.small"}
export EKS_NODE_INSTANCETYPE

: ${EKS_NODE_GRP_TEMPLATE:="https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-02-11/amazon-eks-nodegroup.yaml"}
export EKS_NODE_GRP_TEMPLATE

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

if [ -z ${KUBE_PROVIDER_GEO+x} ]; then export KUBE_PROVIDER_GEO=us-west-2; fi
if [ -z ${KUBE_PROVIDER_MACHINETYPE+x} ]; then export KUBE_PROVIDER_MACHINETYPE="t3.small"; fi


#Backward compatiblity with original scripts
if [ ! -z ${EKS_NODE_INITIALCOUNT+x} ]; then export KUBE_NODE_INITIALCOUNT=${EKS_NODE_INITIALCOUNT}; fi
if [ ! -z ${AWS_REGION+x} ]; then export KUBE_PROVIDER_GEO=${AWS_REGION}; fi
if [ ! -z ${EKS_NODE_INSTANCETYPE+x} ]; then export KUBE_PROVIDER_MACHINETYPE=${EKS_NODE_INSTANCETYPE}; fi

source ${COMMON_DIR}/common-login.sh
echo login.sh KUBE_NAMESPACE ${KUBE_NAMESPACE}
