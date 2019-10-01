#!/bin/sh

source login.sh

# 1. Stop and Delete deployment if one is active
if [[ -f "deployment.id" && -s "deployment.id" ]];
  then
    deployment_id="`cat deployment.id`"
    # Stop deployment
    curl -s -X POST "${SCH_URL}/provisioning/rest/v1/deployment/${deployment_id}/stop" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}"

    # Wait for deployment to become inactive
    deploymentStatus="ACTIVE"
    while [[ "${deploymentStatus}" != "INACTIVE" ]]; do
      echo "\nCurrent Deployment Status is \"${deploymentStatus}\". Waiting for it to become inactive"
      sleep 10
      deploymentStatus=$(curl -X POST -d "[ \"${deployment_id}\" ]" "${SCH_URL}/provisioning/rest/v1/deployments/status" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq -r 'map(select([])|.status)[]')
    done

    # Delete deployment
    curl -s -X DELETE "${SCH_URL}/provisioning/rest/v1/deployment/${deployment_id}" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}"

    rm -f deployment.id
fi

# 2. Delete and Unregister Control Agent if one is active
if [[ -f "agent.id" && -s "agent.id" ]]; then
  agent_id="`cat agent.id`"
  curl -X POST -d "[ \"${agent_id}\" ]" ${SCH_URL}/security/rest/v1/organization/${SCH_ORG}/components/deactivate --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}"
  curl -X POST -d "[ \"${agent_id}\" ]" ${SCH_URL}/security/rest/v1/organization/${SCH_ORG}/components/delete --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}"
  curl -s -X DELETE "${SCH_URL}/provisioning/rest/v1/dpmAgent/${agent_id}" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}"
  rm -f agent.id
fi

# Set namespace
kubectl config set-context $(kubectl config current-context) --namespace=${KUBE_NAMESPACE}


# Delete agent
kubectl delete -f control-agent.yaml
echo "Deleted control agent"


# Delete all secrets
kubectl delete secret compsecret sch-agent-creds
echo "Deleted secret sch-agent-creds"

kubectl delete rolebinding ${SCH_AGENT_NAME}-serviceaccount
kubectl delete role ${SCH_AGENT_NAME}-serviceaccount
kubectl delete serviceaccount ${SCH_AGENT_NAME}-serviceaccount

kubectl delete namespace ${KUBE_NAMESPACE}
echo "Deleted Namespace ${KUBE_NAMESPACE}"
