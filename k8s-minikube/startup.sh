#!/bin/sh

source login.sh

KUBE_USERNAME=minikube

# Set the namespace
kubectl create namespace ${KUBE_NAMESPACE}
kubectl config set-context $(kubectl config current-context) --namespace=${KUBE_NAMESPACE}


kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user="$KUBE_USERNAME"

kubectl create serviceaccount ${SCH_AGENT_NAME}-serviceaccount

kubectl create role ${SCH_AGENT_NAME}-serviceaccount \
    --verb=get,list,create,update,delete \
    --resource=pods,secrets,deployments \

kubectl create rolebinding ${SCH_AGENT_NAME}-serviceaccount \
    --role=${SCH_AGENT_NAME}-serviceaccount \
    --serviceaccount=${KUBE_NAMESPACE_ACTUAL}:${SCH_AGENT_NAME}-serviceaccount \




#######################
# Setup Control Agent #
#######################

# 1. Get a token for Agent from SCH and store it in a secret
AGENT_TOKEN=$(curl -s -X PUT -d "{\"organization\": \"${SCH_ORG}\", \"componentType\" : \"provisioning-agent\", \"numberOfComponents\" : 1, \"active\" : true}" ${SCH_URL}/security/rest/v1/organization/${SCH_ORG}/components --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq '.[0].fullAuthToken')
if [ -z "$AGENT_TOKEN" ]; then
  echo "Failed to generate control agent token."
  echo "Please verify you have Provisioning Operator permissions in SCH"
  exit 1
fi

kubectl create secret generic sch-agent-creds \
    --from-literal=dpm_agent_token_string=${AGENT_TOKEN}

# 2. Create secret for agent to store key pair
kubectl create secret generic compsecret

# 3. Create config map to store configuration referenced by the agent yaml

agent_id=$(uuidgen)
echo ${agent_id} > agent.id
kubectl create configmap streamsets-config \
    --from-literal=org=${SCH_ORG} \
    --from-literal=sch_url=${SCH_URL} \
    --from-literal=agent_id=${agent_id}

# 4. Launch Agent
kubectl create -f control-agent.yaml

# 5. wait for agent to be registered with SCH
temp_agent_Id=""
while [ -z $temp_agent_Id ]; do
  sleep 10
  temp_agent_Id=$(curl -L "${SCH_URL}/provisioning/rest/v1/dpmAgents?organization=${SCH_ORG}" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq -r "map(select(any(.id; contains(\"${agent_id}\")))|.id)[]")
done
echo "DPM Agent \"${temp_agent_Id}\" successfully registered with SCH"
