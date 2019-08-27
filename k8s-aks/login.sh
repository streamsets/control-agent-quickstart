#!/bin/bash
echo Running login.sh

if [ -z "$(which az)" ]; then
  echo "This script requires the 'az cli' utility"
  echo "Please install it via one of the methods described here:"
  echo "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest"
  exit 1
fi

if [ -z ${KUBE_PROVIDER_GEO+x} ]; then export KUBE_PROVIDER_GEO=westus; fi
if [ -z ${KUBE_PROVIDER_MACHINETYPE+x} ]; then export KUBE_PROVIDER_MACHINETYPE=Standard_DS3_v2; fi
if [ -z ${AZURE_RESOURCE_GROUP+x} ]; then export AZURE_RESOURCE_GROUP=${KUBE_CLUSTER_NAME}; fi


#Backward compatiblity with previous scripts
if [ ! -z ${AKS_CLUSTER_NAME+x} ]; then export KUBE_CLUSTER_NAME=${AKS_CLUSTER_NAME}; fi
if [ ! -z ${CREATE_AKS_CLUSTER+x} ]; then export KUBE_CREATE_CLUSTER=${CREATE_AKS_CLUSTER}; fi
if [ ! -z ${DELETE_AKS_CLUSTER+x} ]; then export KUBE_DELETE_CLUSTER=${DELETE_AKS_CLUSTER}; fi



source ../common/common-login.sh

echo Exiting login.sh
