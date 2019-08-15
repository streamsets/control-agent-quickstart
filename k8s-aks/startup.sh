#!/bin/bash
source login.sh

######################
# Create AKS Cluster #
######################

 if [ -n "${KUBE_CREATE_CLUSTER}" ]; then
  # if set, this will also attempt to run the az aks command to provision a cluster
  # create a resource group
  az group create --name "${AZURE_RESOURCE_GROUP}" --location "${KUBE_PROVIDER_GEO}" || { echo 'ERROR: Unable to create resource group' ; exit 1; }
  az aks create --resource-group "${AZURE_RESOURCE_GROUP}" \
  --name "${KUBE_CLUSTER_NAME}" \
  --node-count "${KUBE_NODE_INITIALCOUNT}" \
  --node-vm-size "${KUBE_PROVIDER_MACHINETYPE}" \
  --enable-addons monitoring \
  --generate-ssh-keys || { echo 'ERROR: Unable to create AKS instance' ; exit 1; }
fi
az aks get-credentials --resource-group ${AZURE_RESOURCE_GROUP} --name ${KUBE_CLUSTER_NAME}
# Set the namespace
kubectl create namespace ${KUBE_NAMESPACE}
kubectl config set-context $(kubectl config current-context) --namespace=${KUBE_NAMESPACE}

${COMMON_DIR}/common-startup-services.sh
