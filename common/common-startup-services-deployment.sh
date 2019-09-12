#!/bin/bash
echo Running common-startup-services-deployment.sh on cluster ${KUBE_CLUSTER_NAME}

${COMMON_DIR}/common-kubectl-connect.sh

######################
# Initialize
######################

if [ -z ${SCH_DEPLOYMENT_NAME+x} ]; then export SCH_DEPLOYMENT_NAME=${SCH_AGENT_NAME}-deploy01; fi

agent_id="`cat agent-${SCH_AGENT_NAME}.id`"

echo Agent ID: ${agent_id}
echo K8S Namespace: ${KUBE_NAMESPACE}
echo Docker Image: ${SDC_DOCKER_IMAGE}:${SDC_DOCKER_TAG}

#######################################
# Create Deployment for Authoring SDC #
#######################################
SCH_DEPLOYMENT_LABELS=${SCH_DEPLOYMENT_TYPE},${KUBE_CLUSTER_NAME},${SCH_AGENT_NAME},${SCH_DEPLOYMENT_NAME},${SDC_DOCKER_TAG},all,${SCH_DEPLOYMENT_LABELS}

echo Create Deployment ${SCH_DEPLOYMENT_NAME} with labels: ${SCH_DEPLOYMENT_LABELS}

# Create Secret for Docker credentials (required if private repository)
if [ ! -z ${DOCKER_USER+x} ];
then
  kubectl delete secret dockerstore \
  || { echo 'WARNING: Unable to delete Docker credentials.  If this a new provisioning agent this is expected'; }
  kubectl create secret docker-registry dockerstore --docker-username=${DOCKER_USER} --docker-password=${DOCKER_PASSWORD} --docker-email=${DOCKER_EMAIL} \
  || { echo 'ERROR: Failed to create secret for Docker credentials in Kubernetes' ; exit 1; }
fi

# Create deployment

export KUBE_NAMESPACE
export SDC_DOCKER_IMAGE
export SDC_DOCKER_TAG

case "$SCH_DEPLOYMENT_TYPE" in
  AUTHORING)

    echo ... create service and ingress for Authoring SDC
    # Create Authoring SDC Service and Ingress
    cat ${COMMON_DIR}/authoring-sdc-svc.yaml | envsubst > ${PWD}/_tmp_authoring-sdc-svc.yaml
    kubectl create -f ${PWD}/_tmp_authoring-sdc-svc.yaml  || { echo 'ERROR: Failed to create service for Authoring instance' ; exit 1; }

    echo ... wait for traefik external ip address
    # Wait for an external endpoint to be assigned
    external_ip=""
    #while [ -z $external_ip ]; do
    while [ 1 ]; do
        #This section is a little messy because some K8s implementations return the address in a field named 'ip' and others in field named 'hostname"
        ingress=$(kubectl get svc traefik-ingress-service -o json)
        ingress_host=$(echo $ingress | jq -r 'select(.status.loadBalancer.ingress != null) | .status.loadBalancer.ingress[].hostname')
        if [ -n "${ingress_host}" -a "${ingress_host}" != "null" ];
        then
          external_ip=$ingress_host
          break
        else
          ingress_ip=$(echo $ingress | jq -r 'select(.status.loadBalancer.ingress != null) | .status.loadBalancer.ingress[].ip')
          if [ -n "${ingress_ip}" -a "${ingress_ip}" != "null" ];
          then
            external_ip=$ingress_ip
            break
          fi
        fi
        sleep 10
    done
    echo "External Endpoint to Access Authoring SDC : ${external_ip}\n"
    export external_ip

    cat ${COMMON_DIR}/deployment.yaml | envsubst | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' > ${PWD}/_tmp_deployment.yaml
    ;;
  EXECUTION)
    cat ${COMMON_DIR}/execution-deployment.yaml | envsubst | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' > ${PWD}/_tmp_deployment.yaml
    ;;
  AUTOSCALE)
    cat ${COMMON_DIR}/autoscale-deployment.yaml | envsubst | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' > ${PWD}/_tmp_deployment.yaml
    ;;
  *)
    echo ERROR - Unknown Deployment type: ${SCH_DEPLOYMENT_TYPE}
    exit
esac

DEP_ID=$(curl -s -X PUT -d "{\"name\":\"${SCH_DEPLOYMENT_NAME}\",\"description\":\"Authoring sdc\",\"labels\":[\"${SCH_DEPLOYMENT_LABELS}\"],\"numInstances\":${SDC_REPLICAS},\"spec\":\"$(cat ${PWD}/_tmp_deployment.yaml)\",\"agentId\":\"${agent_id}\"}" "${SCH_URL}/provisioning/rest/v1/deployments" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq -r '.id') || { echo 'ERROR: Failed to create deployment in SCH' ; exit 1; }
echo "Successfully created deployment with ID \"${DEP_ID}\""

# Store Deployment Id in a file for use by the teardwon script.
echo ${DEP_ID} > deployment-${SCH_DEPLOYMENT_NAME}.id

# Start Deployment
curl -s -X POST "${SCH_URL}/provisioning/rest/v1/deployment/${DEP_ID}/start?dpmAgentId=${agent_id}" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" || { echo 'ERROR: Failed to start deployment in SCH' ; exit 1; }
echo "Successfully started deployment \"${SCH_DEPLOYMENT_NAME}\" on Agent \"${agent_id}\""

echo Exiting common-startup-services-deployment.sh on cluster ${KUBE_CLUSTER_NAME}
