#!/bin/sh
set -x
source login.sh

######################
# Create AKS Cluster #
######################

 if [ -n "${CREATE_AKS_CLUSTER}" ]; then
  # if set, this will also attempt to run the az aks command to provision a cluster
  # create a resource group
  az group create --name "${AZURE_RESOURCE_GROUP}" --location "westus"
  az aks create --resource-group "${AZURE_RESOURCE_GROUP}" \
  --name "${CLUSTER_NAME}" \
  --node-count "1" \
  --enable-addons monitoring \
  --generate-ssh-keys
fi
az aks get-credentials --resource-group ${AZURE_RESOURCE_GROUP} --name ${CLUSTER_NAME}
# Set the namespace
kubectl create namespace ${KUBE_NAMESPACE}
kubectl config set-context $(kubectl config current-context) --namespace=${KUBE_NAMESPACE}

########################################################################
# Setup Service Account with roles to read required kubernetes objects #
########################################################################

# GCP_IAM_USERNAME=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin

kubectl create serviceaccount streamsets-agent --namespace=${KUBE_NAMESPACE}
kubectl create role streamsets-agent \
    --verb=get,list,create,update,delete,patch \
    --resource=pods,secrets,replicasets,deployments,ingresses,services,horizontalpodautoscalers \
    --namespace=${KUBE_NAMESPACE}
kubectl create rolebinding streamsets-agent \
    --role=streamsets-agent \
    --serviceaccount=${KUBE_NAMESPACE}:streamsets-agent \
    --namespace=${KUBE_NAMESPACE}

kubectl create serviceaccount traefik-ingress-controller
kubectl create clusterrole traefik-ingress-controller \
    --verb=get,list,watch \
    --resource=endpoints,ingresses.extensions,services,secrets
kubectl create clusterrolebinding traefik-ingress-controller \
    --clusterrole=traefik-ingress-controller \
    --serviceaccount=${KUBE_NAMESPACE}:traefik-ingress-controller

####################################
# Setup Traefik Ingress Controller #
####################################

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
kubectl create configmap traefik-conf --from-file=traefik.toml

# 3. Configure & create traefik service
kubectl create -f traefik-dep.yaml --namespace=${KUBE_NAMESPACE}

# 4. Wait for an external endpoint to be assigned
external_ip=""
while [ -z $external_ip ]; do
    sleep 10
    external_ip=$(kubectl get svc traefik-ingress-service -o json | jq -r 'select(.status.loadBalancer.ingress != null) | .status.loadBalancer.ingress[].ip')
done
echo "External Endpoint to Access Authoring SDC : ${external_ip}\n"

##################################################
# Create a service and ingress for Authoring SDC #
##################################################

# 1. Create Authoring SDC Service and Ingress
kubectl create -f authoring-sdc-svc.yaml

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

#######################################
# Create Deployment for Authoring SDC #
#######################################

# 1. create deployment
deployment_name="authoring-sdc"
DEP_ID=$(curl -s -X PUT -d "{\"name\":\"${deployment_name}\",\"description\":\"Authoring sdc\",\"labels\":[\"authoring-sdc\"],\"numInstances\":1,\"spec\":\"apiVersion: extensions/v1beta1\nkind: Deployment\nmetadata:\n  name: authoring-datacollector\n  namespace: ${KUBE_NAMESPACE}\nspec:\n  replicas: 1\n  template:\n    metadata:\n      labels:\n        app : authoring-datacollector\n    spec:\n      containers:\n      - name : datacollector\n        image: streamsets/datacollector:latest\n        ports:\n        - containerPort: 18630\n        env:\n        - name: SDC_CONF_SDC_BASE_HTTP_URL\n          value: https://${external_ip}:443\n        - name: SDC_CONF_HTTP_ENABLE_FORWARDED_REQUESTS\n          value: true\",\"agentId\":\"${agent_id}\"}" "${SCH_URL}/provisioning/rest/v1/deployments" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}" | jq -r '.id')
echo "Successfully created deployment with ID \"${DEP_ID}\""

# 2. Store Deployment Id in a file for use by the teardown script.
echo ${DEP_ID} > deployment.id

# 3. Start Deployment
curl -s -X POST "${SCH_URL}/provisioning/rest/v1/deployment/${DEP_ID}/start?dpmAgentId=${agent_id}" --header "Content-Type:application/json" --header "X-Requested-By:SDC" --header "X-SS-REST-CALL:true" --header "X-SS-User-Auth-Token:${SCH_TOKEN}"
echo "Successfully started deployment \"${deployment_name}\" on Agent \"${agent_id}\""
