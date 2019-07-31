#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "Usage: startup-services-deployment.sh <deployment name suffix>"
    exit
fi

echo Setting Namespace on Kubectl Context
kubectl config set-context $(kubectl config current-context) --namespace=${KUBE_NAMESPACE} || { echo 'ERROR: Failed to set kubectl context' ; exit 1; }

######################
# Initialize
######################

: ${KUBE_CLUSTER_NAME:="streamsets-quickstart"}
if [ -z ${SCH_AGENT_NAME+x} ]; then export SCH_AGENT_NAME=${KUBE_CLUSTER_NAME}-schagent01; fi
if [ -z ${SCH_DEPLOYMENT_NAME+x} ]; then export SCH_DEPLOYMENT_NAME=${SCH_AGENT_NAME}-deployment${1}; fi
if [ -z ${SCH_DEPLOYMENT_LABELS+x} ]; then export SCH_DEPLOYMENT_LABELS=all,${KUBE_CLUSTER_NAME},${SCH_AGENT_NAME},${SCH_DEPLOYMENT_NAME},${SDC_DOCKERTAG}; fi

echo ... wait for traefik external ip address
# 4. Wait for an external endpoint to be assigned
external_ip=""
#while [ -z $external_ip ]; do
while [ 1 ]; do
    #external_ip=$(kubectl get svc traefik-ingress-service -o json | jq -r 'select(.status.loadBalancer.ingress != null) | .status.loadBalancer.ingress[].ip')
    external_ip=$(kubectl get svc traefik-ingress-service -o json | jq -r 'select(.status.loadBalancer.ingress != null) | .status.loadBalancer.ingress[].hostname')
    if ! [ -z $external_ip ]; then
      break
    fi
    sleep 10
done
echo "External Endpoint to Access Authoring SDC : ${external_ip}\n"

agent_id="`cat agent-${SCH_AGENT_NAME}.id`"
echo Agent ID: ${agent_id}
echo K8S Namespace: ${KUBE_NAMESPACE}
echo Docker Image: ${SDC_DOCKER_IMAGE}:${SDC_DOCKER_TAG}


#######################################
# Create Deployment for Authoring SDC #
#######################################
echo Create Deployment ${SCH_DEPLOYMENT_NAME} with labels: ${SCH_DEPLOYMENT_LABELS}
deployment_name=${SCH_DEPLOYMENT_NAME}

# 0. create Secret for Docker credentials (required if private repository)
if [ ! -z ${DOCKER_USER+x} ];
then
  kubectl delete secret dockerstore \
  || { echo 'WARNING: Unable to delete Docker credentials.  If this a new provisioning agent this is expected'; }
  kubectl create secret docker-registry dockerstore --docker-username=${DOCKER_USER} --docker-password=${DOCKER_PASSWORD} --docker-email=${DOCKER_EMAIL} \
  || { echo 'ERROR: Failed to create secret for Docker credentials in Kubernetes' ; exit 1; }
fi

# 1. create deployment

export KUBE_NAMESPACE
export SDC_DOCKER_IMAGE
export SDC_DOCKER_TAG
export external_ip
cat deployment.yaml | envsubst | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' > ${PROVIDER_DIR}/_tmp_deployment.yaml
DEP_ID=$(curl -s -X PUT -d "{\"name\":\"${deployment_name}\",\"description\":\"Authoring sdc\",\"labels\":[\"${SCH_DEPLOYMENT_LABELS}\"],\"numInstances\":1,\"spec\":\"$(cat ${PROVIDER_DIR}/_tmp_deployment.yaml)\",\"agentId\":\"${agent_id}\"}" "${SCH_URL}/provisioning/rest/v1/deployments" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq -r '.id') || { echo 'ERROR: Failed to create deployment in SCH' ; exit 1; }
echo "Successfully created deployment with ID \"${DEP_ID}\""

# 2. Store Deployment Id in a file for use by the teardwon script.
echo ${DEP_ID} > deployment-${SCH_DEPLOYMENT_NAME}.id

# 3. Start Deployment
curl -s -X POST "${SCH_URL}/provisioning/rest/v1/deployment/${DEP_ID}/start?dpmAgentId=${agent_id}" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" || { echo 'ERROR: Failed to start deployment in SCH' ; exit 1; }
echo "Successfully started deployment \"${deployment_name}\" on Agent \"${agent_id}\""
