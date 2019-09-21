#!/bin/bash
echo Running common-teardown-services-deployment.sh on cluster ${KUBE_CLUSTER_NAME}

${COMMON_DIR}/common-kubectl-connect.sh

# 1. Stop and Delete deployment if one is active
echo "Stop and Delete deployment if one is active"

# Stop deployment
if [[ -f "deployment-${SCH_DEPLOYMENT_NAME}.id" && -s "deployment-${SCH_DEPLOYMENT_NAME}.id" ]]; then
  echo Deleting deployment
  deployment_id="`cat deployment-${SCH_DEPLOYMENT_NAME}.id`"
  deploymentStatus=$(curl -X POST -d "[ \"${deployment_id}\" ]" "${SCH_URL}/provisioning/rest/v1/deployments/status" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq -r 'map(select([])|.status)[]')

  # Wait for deployment to become inactive
  while [[ "${deploymentStatus}" != "INACTIVE" ]]; do
    echo "\nCurrent Deployment Status is \"${deploymentStatus}\". Waiting for it to become inactive"
    sleep 10
    #Clear any pending errors
    deploymentStatus=$(curl -X POST -d "[ \"${deployment_id}\" ]" "${SCH_URL}/provisioning/rest/v1/deployments/acknowledgeErrors" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq -r 'map(select([])|.status)[]')
    #Refresh status
    deploymentStatus=$(curl -X POST -d "[ \"${deployment_id}\" ]" "${SCH_URL}/provisioning/rest/v1/deployments/status" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq -r 'map(select([])|.status)[]')
  done
fi

# Delete deployment
curl -s -X DELETE "${SCH_URL}/provisioning/rest/v1/deployment/${deployment_id}" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}"

rm -f deployment-${SCH_DEPLOYMENT_NAME}.id

echo ... create service and ingress for Authoring SDC

#Deleting Authoring SDC Service and Ingress
cat ${COMMON_DIR}/authoring-sdc-svc.yaml | envsubst > ${PWD}/_tmp_authoring-sdc-svc.yaml
kubectl delete -f ${PWD}/_tmp_authoring-sdc-svc.yaml

${COMMON_DIR}/common-teardown-traefik.sh

echo Exiting common-teardown-services-deployment.sh on cluster ${KUBE_CLUSTER_NAME}
