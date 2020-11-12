#!/bin/bash
source login.sh

######################
# Create AKS Cluster #
######################

if [ "$KUBE_CREATE_CLUSTER" == "1" ]; then
  if [ -n "${AZURE_SUBSCRIPTION}" ]; then
    echo ... setting Subscription ${AZURE_SUBSCRIPTION}
    az account set --subscription "${AZURE_SUBSCRIPTION}"
  fi
  echo Creating K8s Cluster
  # if set, this will also attempt to run the az aks command to provision a cluster
  # create a resource group
  echo ... creating Resource Group ${AZURE_RESOURCE_GROUP}
  az group create --name "${AZURE_RESOURCE_GROUP}" --location "${KUBE_PROVIDER_GEO}" || { echo 'ERROR: Unable to create resource group' ; exit 1; }
  echo ... creating Cluster
  az aks create --resource-group "${AZURE_RESOURCE_GROUP}" \
  --subscription "${AZURE_SUBSCRIPTION}" \
  --name "${KUBE_CLUSTER_NAME}" \
  --node-count "${KUBE_NODE_INITIALCOUNT}" \
  --node-vm-size "${KUBE_PROVIDER_MACHINETYPE}" \
  --enable-addons monitoring \
  --generate-ssh-keys || { echo 'ERROR: Unable to create AKS instance' ; exit 1; }

  echo Configuring kubectl
  az aks get-credentials --resource-group ${AZURE_RESOURCE_GROUP} --name ${KUBE_CLUSTER_NAME}

fi

${COMMON_DIR}/common-startup-services.sh
