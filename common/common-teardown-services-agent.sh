#!/bin/bash
echo Running common-teardown-services-agent.sh on cluster ${KUBE_CLUSTER_NAME}

if [ $# -eq 0 ]
  then
    echo "Usage: teardown-services-agent.sh <agent name suffix>"
    exit
fi

echo Setting Namespace on Kubectl Context
kubectl config set-context $(kubectl config current-context) --namespace=${KUBE_NAMESPACE} || { echo 'ERROR: Failed to set kubectl context' ; exit 1; }

######################
# Initialize
######################

# 2. Delete and Unregister Control Agent if one is active
if [[ -f "agent-${SCH_AGENT_NAME}.id" && -s "agent-${SCH_AGENT_NAME}.id" ]]; then
    agent_id="`cat agent-${SCH_AGENT_NAME}.id`"
    echo Agent ID: ${agent_id}
    echo K8S Namespace: ${KUBE_NAMESPACE}

    # 1. Stop and Delete deployment if one is active
    echo "Stop and Delete deployment if one is active"
    #TODO Should dynically discover deployment names via REST API based on agent name
    for i in deployment-${SCH_AGENT_NAME}*.id; do
            [ -f "$i" ] || break # break if zero matches
            deployment_id="`cat $i`"
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

            rm -f $i

    done

    # Delete agent
    echo "Deactivate and delete agent"
    echo "... Deactivate and delete in SCH"
    agent_id="`cat agent-${SCH_AGENT_NAME}.id`"
    curl -X POST -d "[ \"${agent_id}\" ]" ${SCH_URL}/security/rest/v1/organization/${SCH_ORG}/components/deactivate --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}"
    curl -X POST -d "[ \"${agent_id}\" ]" ${SCH_URL}/security/rest/v1/organization/${SCH_ORG}/components/delete --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}"
    curl -s -X DELETE "${SCH_URL}/provisioning/rest/v1/dpmAgent/${agent_id}" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}"
    rm -f agent-${SCH_AGENT_NAME}.id

    echo "... Delete K8s Pod"
    cat ${COMMON_DIR}/control-agent.yaml | envsubst > ${PROVIDER_DIR}/_tmp_control-agent.yaml
    kubectl delete -f ${PROVIDER_DIR}/_tmp_control-agent.yaml
    echo "Deleted control agent"

    # Delete secrets
    echo "... Delete agent secrets"
    kubectl delete secret ${SCH_AGENT_NAME}-creds \
        || { echo 'ERROR: Failed to delete SCH credentials secret in Kubernetes'; }
    kubectl delete secret ${SCH_AGENT_NAME}-compsecret \
        || { echo 'ERROR: Failed to delete agent keypair secret in Kubernetes' ; }

    # Delete configMap
    echo "... Delete agent configmap"
    kubectl delete configmap ${SCH_AGENT_NAME}-config \
        || { echo 'ERROR: Failed to create configmap in Kubernetes' ; exit 1; }



else
    echo "File not found: agent-${SCH_AGENT_NAME}.id"
fi

echo Exiting common-teardown-services-agent.sh on cluster ${KUBE_CLUSTER_NAME}
