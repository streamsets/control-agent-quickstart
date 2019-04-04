#!/bin/bash
export PATH=$HOME/bin/aws-iam-authenticator:$PATH

# AWS EKS
#---------------------------------------
export EKS_IAM_ROLE="arn:aws:iam::179521618147:role/eksServiceRole"

us-west-2 Region parameters
export AWS_REGION=us-west-2
export AWS_KEYPAIR_NAME=MyEC2KeyPair-west-2
export EKS_NODE_IMAGEID="ami-081099ec932b99961" #us-west-2 amazon-eks-node-1.11-v20190211

#us-east-1 Region parameters
#export AWS_REGION=us-east-1
#export AWS_KEYPAIR_NAME=MyEC2KeyPair
#export EKS_VPC_TEMPLATE=file://${PWD}/amazon-eks-vpc-sample-acd.yaml
#export EKS_NODE_IMAGEID="ami-0c5b63ec54dd3fc38" #us-east-1 amazon-eks-node-1.11-v20190211


# Kuberenetes
#---------------------------------------
export KUBE_CLUSTER_NAME=sdc-cluster-1
export KUBE_CREATE_CLUSTER=1
export KUBE_DELETE_CLUSTER=1


# StreamSets
#---------------------------------------
export SCH_URL=http://35.247.124.58:18631
export SCH_ORG=sko
export SCH_USER=sko@sko
export SCH_PASSWORD=streamsets

export SDC_DOCKER_TAG=latest
#export SDC_DOCKER_TAG=3.0.0.0
