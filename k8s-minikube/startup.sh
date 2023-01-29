#!/bin/sh

#######################################
# Debug Commands. Uncomment As Needed #
#######################################
# set -e # Stop at first error
# set -x # Print commands
# set -v # Print shell input lines as they are read

source login.sh
source ${COMMON_DIR}/common-kubectl-connect.sh

KUBE_USERNAME=minikube

# Set the namespace
$KUBE_EXEC create namespace ${KUBE_NAMESPACE}
$KUBE_EXEC config use-context $(kubectl config current-context) --namespace=${KUBE_NAMESPACE}

echo ... create service acount
$KUBE_EXEC create serviceaccount ${SCH_AGENT_NAME}-serviceaccount

echo ... create role
$KUBE_EXEC create role ${SCH_AGENT_NAME}-role \
    --verb=get,list,create,update,delete,patch \
    --resource=pods,secrets,ingresses,services,horizontalpodautoscalers,replicasets.apps,deployments.apps,replicasets.apps,deployments

echo ... create rolebining
$KUBE_EXEC create rolebinding ${SCH_AGENT_NAME}-rolebinding \
    --role=${SCH_AGENT_NAME}-role \
    --serviceaccount=${KUBE_NAMESPACE}:${SCH_AGENT_NAME}-serviceaccount

#######################
# Setup Control Agent #
#######################

# 1. Get a token for Agent from SCH and store it in a secret
echo ... Get a token for Agent from SCH and store it in a secret
AGENT_TOKEN_CURL=$(curl -s -X PUT -d "{\"organization\": \"${SCH_ORG}\", \"componentType\" : \"provisioning-agent\", \"numberOfComponents\" : 1, \"active\" : true}" ${SCH_URL}/security/rest/v1/organization/${SCH_ORG}/components --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}")
CURL_ISSUES=$(echo ${AGENT_TOKEN_CURL} | jq ".ISSUES")
if [ ! -z "$CURL_ISSUES" ]; then
  echo "ERROR: Problem encountered while requesting agent token: $CURL_ISSUES"
  exit
fi
AGENT_TOKEN=$(echo ${AGENT_TOKEN_CURL} | jq '.[0].fullAuthToken')

if [ -z "$AGENT_TOKEN" ]; then
  echo "ERROR: Failed to retrieve control agent token."
  exit 1
else
  echo "   Agent token successfully retrieved"
fi

echo ... Create secret from agent token
$KUBE_EXEC create secret generic ${SCH_AGENT_NAME}-creds \
    --from-literal=dpm_agent_token_string=${AGENT_TOKEN}

# 2. Create secret for agent to store key pair
echo ... Create secret for agent to store key pair
$KUBE_EXEC create secret generic ${SCH_AGENT_NAME}-compsecret

# 3. Create config map to store configuration referenced by the agent yaml
echo ... Create config map to store configuration referenced by the agent yaml
agent_id=$(uuidgen)
echo ${agent_id} > agent-${SCH_AGENT_NAME}.id
$KUBE_EXEC create configmap ${SCH_AGENT_NAME}-config \
    --from-literal=org=${SCH_ORG} \
    --from-literal=sch_url=${SCH_URL} \
    --from-literal=agent_id=${agent_id}

# 4. Launch Agent
echo ... Launch Agent
cat control-agent.yaml | envsubst > ${PWD}/_tmp_control-agent.yaml
$KUBE_EXEC create -f ${PWD}/_tmp_control-agent.yaml

# 5. wait for agent to be registered with SCH
temp_agent_Id=""
while [ -z $temp_agent_Id ]; do
  sleep 10
  curl -L "${SCH_URL}/provisioning/rest/v1/dpmAgents?organization=${SCH_ORG}" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq -r "map(select(any(.id; contains(\"${agent_id}\")))|.id)[]"
  temp_agent_Id=$(curl -L "${SCH_URL}/provisioning/rest/v1/dpmAgents?organization=${SCH_ORG}" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq -r "map(select(any(.id; contains(\"${agent_id}\")))|.id)[]")
done
echo "DPM Agent \"${temp_agent_Id}\" successfully registered with SCH"
