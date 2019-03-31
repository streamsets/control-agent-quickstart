#!/bin/bash 
export PATH=$HOME/bin/aws-iam-authenticator:$PATH

export SCH_URL=http://35.247.24.43:18631
export SCH_ORG=sko
export SCH_USER=sko@sko 
export SCH_PASSWORD=streamsets
export KUBE_CLUSTER_NAME=august-cluster-1
export AWS_REGION=us-west-2

export EKS_IAM_ROLE="arn:aws:iam::179521618147:role/eksServiceRole"
export AWS_KEYPAIR_NAME=MyEC2KeyPair-west-2
#export SDC_DOCKER_TAG=3.0.0.0
export SDC_DOCKER_TAG=latest
