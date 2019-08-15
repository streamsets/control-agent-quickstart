#!/bin/bash
source login.sh

######################
# Create EKS Cluster #
######################

AWS_REGION=${KUBE_PROVIDER_GEO}

EKS_NODE_GROUP_NAME=${KUBE_CLUSTER_NAME}-nodegrp-1
if [ "$KUBE_CREATE_CLUSTER" == "1" ]; then
  # if set, this will also attempt to provision an EKS cluster
  echo creating new k8s cluster...
  echo ... creating vpc
  if [[ $EKS_VPC_TEMPLATE == http* ]]; then
    aws cloudformation create-stack --region=${AWS_REGION} --stack-name ${KUBE_CLUSTER_NAME}-vpc --template-url $EKS_VPC_TEMPLATE
  else
    aws cloudformation create-stack --region=${AWS_REGION} --stack-name ${KUBE_CLUSTER_NAME}-vpc --template-body $EKS_VPC_TEMPLATE
  fi
  aws cloudformation wait stack-create-complete --region=${AWS_REGION} --stack-name ${KUBE_CLUSTER_NAME}-vpc
  AWS_SEC_GRP=$(aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${KUBE_CLUSTER_NAME}-vpc | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="SecurityGroups").OutputValue')
  AWS_SUBNET_IDS=$(aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${KUBE_CLUSTER_NAME}-vpc | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="SubnetIds").OutputValue')
  AWS_VPC_ID=$(aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${KUBE_CLUSTER_NAME}-vpc | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="VpcId").OutputValue')
  echo ${AWS_SEC_GRP}
  echo $AWS_SUBNET_IDS
  echo $AWS_VPC_ID

  echo ... creating cluster
  aws eks --region ${AWS_REGION} create-cluster \
    --name "${KUBE_CLUSTER_NAME}" \
    --role-arn ${EKS_IAM_ROLE} \
    --resources-vpc-config subnetIds=${AWS_SUBNET_IDS},securityGroupIds=${AWS_SEC_GRP}

  echo ... waiting for cluster to become active
  aws eks --region ${AWS_REGION} wait cluster-active --name "${KUBE_CLUSTER_NAME}"

  echo ... configuring kubectl
  aws eks --region ${AWS_REGION} update-kubeconfig --name "${KUBE_CLUSTER_NAME}"

  echo ... creating nodes
#AWS_SUBNETS_ID=${AWS_SUBNETS_ID//,/\.}
#echo $AWS_SUBNET_IDS
  aws cloudformation create-stack --region ${AWS_REGION} --stack-name ${EKS_NODE_GROUP_NAME} --template-url $EKS_NODE_GRP_TEMPLATE \
    --capabilities CAPABILITY_IAM \
    --parameters ParameterKey=NodeGroupName,ParameterValue=${KUBE_CLUSTER_NAME}-nodegrp-1 \
         ParameterKey=ClusterName,ParameterValue=${KUBE_CLUSTER_NAME} \
         ParameterKey=ClusterControlPlaneSecurityGroup,ParameterValue=${AWS_SEC_GRP} \
         ParameterKey=VpcId,ParameterValue=${AWS_VPC_ID} \
         ParameterKey=Subnets,ParameterValue="'${AWS_SUBNET_IDS}'" \
         ParameterKey=KeyName,ParameterValue=${AWS_KEYPAIR_NAME} \
         ParameterKey=NodeImageId,ParameterValue=${EKS_NODE_IMAGEID} \
         ParameterKey=NodeInstanceType,,ParameterValue=${EKS_NODE_INSTANCETYPE} \
         ParameterKey=NodeGroupName,ParameterValue=${EKS_NODE_GROUP_NAME} \
         ParameterKey=NodeAutoScalingGroupDesiredCapacity,ParameterValue=${KUBE_NODE_INITIALCOUNT} \
         ParameterKey=NodeAutoScalingGroupMaxSize,ParameterValue=$((${KUBE_NODE_INITIALCOUNT}+1))


  echo ... waiting for nodes to start
  aws cloudformation wait stack-create-complete --region=${AWS_REGION} --stack-name ${EKS_NODE_GROUP_NAME}

  echo ... adding aws-auth config map to K8s
  curl -o _tmp_aws-auth-cm.yaml -O https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-02-11/aws-auth-cm.yaml
  EKS_NODE_INSTANCEROLE=$(aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${EKS_NODE_GROUP_NAME} | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="NodeInstanceRole").OutputValue')
  sed -i 's,<ARN of instance role (not instance profile)>,'"${EKS_NODE_INSTANCEROLE}"',' _tmp_aws-auth-cm.yaml
  kubectl apply -f _tmp_aws-auth-cm.yaml
fi

echo Configuring K8s Cluster
echo ... configuring kubectl
aws eks --region ${AWS_REGION} update-kubeconfig --name "${KUBE_CLUSTER_NAME}" --alias "${KUBE_CLUSTER_NAME}"     || { echo 'ERROR: Failed to configure kubectl' ; exit 1; }
echo ... create namespace
kubectl create namespace ${KUBE_NAMESPACE} || { echo 'ERROR: Failed to create namespace in Kubernetes' ; exit 1; }

${COMMON_DIR}/common-startup-services.sh
