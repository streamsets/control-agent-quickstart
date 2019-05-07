#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "Usage: startup-agent.sh <agent name suffix>"
    exit
fi

source login.sh
source eks-env.sh

######################
# Initialize
######################

: ${KUBE_CLUSTER_NAME:="streamsets-quickstart"}
if [ -z ${SCH_AGENT_NAME+x} ]; then export SCH_AGENT_NAME=${KUBE_CLUSTER_NAME}-schagent${1}; fi

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

echo K8S Namespace: ${KUBE_NAMESPACE}
echo Agent name: ${SCH_AGENT_NAME}

#######################
# Setup Control Agent #
#######################
echo Setup Control Agent

# 1. Get a token for Agent from SCH and store it in a secret
echo ... Get a token for Agent from SCH and store it in a secret
AGENT_TOKEN=$(curl -s -X PUT -d "{\"organization\": \"${SCH_ORG}\", \"componentType\" : \"provisioning-agent\", \"numberOfComponents\" : 1, \"active\" : true}" ${SCH_URL}/security/rest/v1/organization/${SCH_ORG}/components --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq '.[0].fullAuthToken')
#TODO Capture "Issues" in curl response
if [ -z "$AGENT_TOKEN" ]; then
  echo "Failed to generate control agent token."
  echo "Please verify you have Provisioning Operator permissions in SCH"
  exit 1
fi
kubectl create secret generic ${SCH_AGENT_NAME}-creds \
    --from-literal=dpm_agent_token_string=${AGENT_TOKEN} \
    || { echo 'ERROR: Failed to create SCH credentials secret in Kubernetes' ; exit 1; }

# 2. Create secret for agent to store key pair
echo ... Create secret for agent to store key pair
kubectl create secret generic ${SCH_AGENT_NAME}-compsecret \
|| { echo 'ERROR: Failed to create agent keypair secret in Kubernetes' ; exit 1; }

# 3. Create config map to store configuration referenced by the agent yaml
echo ... Create config map to store configuration referenced by the agent yaml
agent_id=$(uuidgen)
echo ${agent_id} > agent-${SCH_AGENT_NAME}.id
kubectl create configmap ${SCH_AGENT_NAME}-config \
    --from-literal=org=${SCH_ORG} \
    --from-literal=sch_url=${SCH_URL} \
    --from-literal=agent_id=${agent_id} \
    || { echo 'ERROR: Failed to create configmap in Kubernetes' ; exit 1; }

# 4. Launch Agent
echo ... Launch Agent
cat control-agent.yaml | envsubst > _tmp_control-agent.yaml
#exit
#cat control-agent.yaml | envsubst | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' > _tmp_control-agent.yaml
kubectl create -f _tmp_control-agent.yaml || { echo 'ERROR: Failed to launch Streamsets Control Agent in Kubernetes' ; exit 1; }

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
./startup-deployment.sh 01
