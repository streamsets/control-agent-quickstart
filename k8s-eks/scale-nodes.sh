#!/bin/bash

AWS_REGION=${KUBE_PROVIDER_GEO}

if [ $# -eq 0 ]
  then
    echo "Usage: scale-nodes.sh <number of desired nodes>"
    exit
fi

if [ $1 -lt 0 ]
  then
    echo "Error: Requested number of nodes is negative (${1})"
    exit
fi


source login.sh

######################
# Create EKS Cluster #
######################

# : ${KUBE_CLUSTER_NAME:="streamsets-quickstart"}
# #if [ -z ${SCH_AGENT_NAME+x} ]; then export SCH_AGENT_NAME=${KUBE_CLUSTER_NAME}-schagent; fi
# #if [ -z ${SCH_DEPLOYMENT_NAME+x} ]; then export SCH_DEPLOYMENT_NAME=${SCH_AGENT_NAME}-deployment-01; fi
# #if [ -z ${SCH_DEPLOYMENT_LABELS+x} ]; then export SCH_DEPLOYMENT_LABELS=all,${KUBE_CLUSTER_NAME},${SCH_AGENT_NAME},${SCH_DEPLOYMENT_NAME},${SDC_DOCKERTAG}; fi
#
EKS_NODE_GROUP_NAME=${KUBE_CLUSTER_NAME}-nodegrp-1
# # if set, this will also attempt to provision an EKS cluster
# echo ... collecting vpc stack information ...
# AWS_SEC_GRP=$(aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${KUBE_CLUSTER_NAME}-vpc | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="SecurityGroups").OutputValue')
# AWS_SUBNET_IDS=$(aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${KUBE_CLUSTER_NAME}-vpc | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="SubnetIds").OutputValue')
# AWS_VPC_ID=$(aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${KUBE_CLUSTER_NAME}-vpc | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="VpcId").OutputValue')
# echo ${AWS_SEC_GRP}
# echo $AWS_SUBNET_IDS
# echo $AWS_VPC_ID


echo ${KUBE_CLUSTER_NAME}
echo ${EKS_NODE_GROUP_NAME}

echo ... verifying cluster is active
aws eks --region ${AWS_REGION} wait cluster-active --name "${KUBE_CLUSTER_NAME}"

echo ... configuring kubectl
aws eks --region ${AWS_REGION} update-kubeconfig --name "${KUBE_CLUSTER_NAME}"

AWS_SEC_GRP=$(aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${KUBE_CLUSTER_NAME}-vpc | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="SecurityGroups").OutputValue')
AWS_SUBNET_IDS=$(aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${KUBE_CLUSTER_NAME}-vpc | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="SubnetIds").OutputValue')
AWS_VPC_ID=$(aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${KUBE_CLUSTER_NAME}-vpc | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="VpcId").OutputValue')
echo ${AWS_SEC_GRP}
echo $AWS_SUBNET_IDS
echo $AWS_VPC_ID

#echo ... getting autoscaling group name
#EKS_NODE_GROUP_AUTOSCALING_GROUP=$(aws cloudformation describe-stack-resources --region ${AWS_REGION} --stack-name ${EKS_NODE_GROUP_NAME} | jq -r '.StackResources[] | select(.ResourceType=="AWS::AutoScaling::AutoScalingGroup").PhysicalResourceId')
#aws autoscaling update-auto-scaling-group --region ${AWS_REGION} --stack-name ${EKS_NODE_GROUP_AUTOSCALING_GROUP} --desired-capacity $1 --max-size $(($1+1))
echo ... scaling nodes to $1
aws cloudformation update-stack --region ${AWS_REGION} --stack-name ${EKS_NODE_GROUP_NAME} --use-previous-template \
  --capabilities CAPABILITY_IAM \
  --parameters ParameterKey=NodeGroupName,ParameterValue=${KUBE_CLUSTER_NAME}-nodegrp-1 \
       ParameterKey=ClusterName,ParameterValue=${KUBE_CLUSTER_NAME} \
       ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue=${AWS_SEC_GRP} \
       ParameterKey=VpcId,ParameterValue=${AWS_VPC_ID} \
       ParameterKey=Subnets,ParameterValue="'${AWS_SUBNET_IDS}'" \
       ParameterKey=KeyName,ParameterValue=${AWS_KEYPAIR_NAME} \
       ParameterKey=NodeImageId,ParameterValue=${EKS_NODE_IMAGEID} \
       ParameterKey=NodeInstanceType,,ParameterValue=${EKS_NODE_INSTANCETYPE} \
       ParameterKey=NodeGroupName,ParameterValue=${EKS_NODE_GROUP_NAME}\
       ParameterKey=NodeAutoScalingGroupMinSize,ParameterValue=${1} \
       ParameterKey=NodeAutoScalingGroupDesiredCapacity,ParameterValue=${1} \
       ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=$(($1+1))

echo ... waiting for nodes to scaling to complete
aws cloudformation wait stack-update-complete --region=${AWS_REGION} --stack-name ${EKS_NODE_GROUP_NAME}
