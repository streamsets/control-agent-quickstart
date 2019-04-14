#!/bin/bash

source login.sh
echo DEBUG login.sh complete
source eks-env.sh

######################
# Create EKS Cluster #
######################

: ${KUBE_CLUSTER_NAME:="streamsets-quickstart"}
if [ -z ${SCH_AGENT_NAME+x} ]; then export SCH_AGENT_NAME=${KUBE_CLUSTER_NAME}-schagent; fi
if [ -z ${SCH_DEPLOYMENT_NAME+x} ]; then export SCH_DEPLOYMENT_NAME=${SCH_AGENT_NAME}-deployment-01; fi
if [ -z ${SCH_DEPLOYMENT_LABELS+x} ]; then export SCH_DEPLOYMENT_LABELS=all,${KUBE_CLUSTER_NAME},${SCH_AGENT_NAME},${SCH_DEPLOYMENT_NAME},${SDC_DOCKERTAG}; fi

EKS_NODE_GROUP_NAME=${KUBE_CLUSTER_NAME}-nodegrp-1
if [ -n "$KUBE_CREATE_CLUSTER" ]; then
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
         ParameterKey=NodeGroupName,ParameterValue=${EKS_NODE_GROUP_NAME}

  echo ... waiting for nodes to start
  aws cloudformation wait stack-create-complete --region=${AWS_REGION} --stack-name ${EKS_NODE_GROUP_NAME}

  echo ... adding nodes to cluster
  curl -O https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-02-11/aws-auth-cm.yaml
  EKS_NODE_INSTANCEROLE=$(aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${EKS_NODE_GROUP_NAME} | jq -r '.Stacks[].Outputs[] | select(.OutputKey=="NodeInstanceRole").OutputValue')
  sed -i 's,<ARN of instance role (not instance profile)>,'"${EKS_NODE_INSTANCEROLE}"',' aws-auth-cm.yaml
  kubectl apply -f aws-auth-cm.yaml
fi

echo Configuring K8s Cluster
echo ... configuring kubectl
aws eks --region ${AWS_REGION} update-kubeconfig --name "${KUBE_CLUSTER_NAME}"
echo ... create namespace
kubectl create namespace ${KUBE_NAMESPACE}
echo ... set context
kubectl config set-context $(kubectl config current-context) --namespace=${KUBE_NAMESPACE}

########################################################################
# Setup Service Account with roles to read required kubernetes objects #
########################################################################

echo Setup Service Account
echo ... create service acount
kubectl create serviceaccount streamsets-agent --namespace=${KUBE_NAMESPACE}
echo ... create role
kubectl create role streamsets-agent \
    --verb=get,list,create,update,delete,patch \
    --resource=pods,secrets,replicasets,deployments,ingresses,services,horizontalpodautoscalers \
    --namespace=${KUBE_NAMESPACE}
echo ... create rolebining
kubectl create rolebinding streamsets-agent \
    --role=streamsets-agent \
    --serviceaccount=${KUBE_NAMESPACE}:streamsets-agent \
    --namespace=${KUBE_NAMESPACE}

echo ... create serviceaccount
kubectl create serviceaccount traefik-ingress-controller
echo ... create clusterrole
kubectl create clusterrole traefik-ingress-controller \
    --verb=get,list,watch \
    --resource=endpoints,ingresses.extensions,services,secrets
echo ... create clusterrolebinding
kubectl create clusterrolebinding traefik-ingress-controller \
    --clusterrole=traefik-ingress-controller \
    --serviceaccount=${KUBE_NAMESPACE}:traefik-ingress-controller

####################################
# Setup Traefik Ingress Controller #
####################################

echo Setup Traefik Ingress Controller
echo ... generate self signed certificate
# 1. Generate self signed certificate and create a secret
openssl req -newkey rsa:2048 \
    -nodes \
    -keyout tls.key \
    -x509 \
    -days 365 \
    -out tls.crt \
    -subj "/C=US/ST=California/L=San Francisco/O=My Company/CN=mycompany.com"
kubectl create secret generic traefik-cert \
    --from-file=tls.crt \
    --from-file=tls.key

# 2. Create traefik configuration to handle https
echo ... create configmap
kubectl create configmap traefik-conf --from-file=traefik.toml

# 3. Configure & create traefik service
echo ... create traefik service
kubectl create -f traefik-dep.yaml --namespace=${KUBE_NAMESPACE}

# 4. Wait for an external endpoint to be assigned
echo ... wait for traefik external ip address
external_ip=""
while [ -z $external_ip ]; do
    sleep 10
    #external_ip=$(kubectl get svc traefik-ingress-service -o json | jq -r 'select(.status.loadBalancer.ingress != null) | .status.loadBalancer.ingress[].ip')
    external_ip=$(kubectl get svc traefik-ingress-service -o json | jq -r 'select(.status.loadBalancer.ingress != null) | .status.loadBalancer.ingress[].hostname')
done
echo "External Endpoint to Access Authoring SDC : ${external_ip}\n"

##################################################
# Create a service and ingress for Authoring SDC #
##################################################

echo Create a service and ingress for Authoriing SDC
# 1. Create Authoring SDC Service and Ingress
kubectl create -f authoring-sdc-svc.yaml

#######################
# Setup Control Agent #
#######################
echo Setup Control Agent

# 1. Get a token for Agent from SCH and store it in a secret
echo ... Get a token for Agent from SCH and store it in a secret
AGENT_TOKEN=$(curl -s -X PUT -d "{\"organization\": \"${SCH_ORG}\", \"componentType\" : \"provisioning-agent\", \"numberOfComponents\" : 1, \"active\" : true}" ${SCH_URL}/security/rest/v1/organization/${SCH_ORG}/components --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq '.[0].fullAuthToken')
if [ -z "$AGENT_TOKEN" ]; then
  echo "Failed to generate control agent token."
  echo "Please verify you have Provisioning Operator permissions in SCH"
  exit 1
fi
kubectl create secret generic sch-agent-creds \
    --from-literal=dpm_agent_token_string=${AGENT_TOKEN}

# 2. Create secret for agent to store key pair
echo ... Create secret for agent to store key pair
kubectl create secret generic compsecret

# 3. Create config map to store configuration referenced by the agent yaml
echo ... Create config map to store configuration referenced by the agent yaml
agent_id=$(uuidgen)
echo ${agent_id} > agent.id
kubectl create configmap streamsets-config \
    --from-literal=org=${SCH_ORG} \
    --from-literal=sch_url=${SCH_URL} \
    --from-literal=agent_id=${agent_id}

# 4. Launch Agent
echo ... Launch Agent
cat control-agent.yaml |  sed -e 's/@@agent-name@@/'${SCH_AGENT_NAME}'/g' > _tmp_control-agent.yaml
kubectl create -f _tmp_control-agent.yaml

# 5. wait for agent to be registered with SCH
echo ... wait for agent to be registered with SCH
temp_agent_Id=""
while [ -z $temp_agent_Id ]; do
  sleep 10
  temp_agent_Id=$(curl -L "${SCH_URL}/provisioning/rest/v1/dpmAgents?organization=${SCH_ORG}" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq -r "map(select(any(.id; contains(\"${agent_id}\")))|.id)[]")
done
echo "DPM Agent \"${temp_agent_Id}\" successfully registered with SCH"

#######################################
# Create Deployment for Authoring SDC #
#######################################
echo Create Deployment ${SCH_DEPLOYMENT_NAME} with labels: ${SCH_DEPLOYMENT_LABELS}
deployment_name=${SCH_DEPLOYMENT_NAME}

# 1. create deployment
DEP_ID=$(curl -s -X PUT -d "{\"name\":\"${deployment_name}\",\"description\":\"Authoring sdc\",\"labels\":[\"${SCH_DEPLOYMENT_LABELS}\"],\"numInstances\":1,\"spec\":\"apiVersion: extensions/v1beta1\nkind: Deployment\nmetadata:\n  name: authoring-datacollector\n  namespace: ${KUBE_NAMESPACE}\nspec:\n  replicas: 1\n  template:\n    metadata:\n      labels:\n        app : authoring-datacollector\n    spec:\n      containers:\n      - name : datacollector\n        image: streamsets/datacollector:${SDC_DOCKERTAG}\n        ports:\n        - containerPort: 18630\n        env:\n        - name: SDC_CONF_SDC_BASE_HTTP_URL\n          value: https://${external_ip}:443\n        - name: SDC_CONF_HTTP_ENABLE_FORWARDED_REQUESTS\n          value: true\",\"agentId\":\"${agent_id}\"}" "${SCH_URL}/provisioning/rest/v1/deployments" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq -r '.id')
echo "Successfully created deployment with ID \"${DEP_ID}\""

# 2. Store Deployment Id in a file for use by the teardwon script.
echo ${DEP_ID} > deployment.id

# 3. Start Deployment
curl -s -X POST "${SCH_URL}/provisioning/rest/v1/deployment/${DEP_ID}/start?dpmAgentId=${agent_id}" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}"
echo "Successfully started deployment \"${deployment_name}\" on Agent \"${agent_id}\""
