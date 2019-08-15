#!/bin/bash
echo Running login.sh

export PROVIDER_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export COMMON_DIR=`echo $(cd ${PROVIDER_DIR}/../common; pwd)`

if [ -z "$(which az)" ]; then
  echo "This script requires the 'az cli' utility"
  echo "Please install it via one of the methods described here:"
  echo "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest"
  exit 1
fi

if [ -z ${KUBE_PROVIDER_GEO+x} ]; then export KUBE_PROVIDER_GEO=westus; fi
if [ -z ${KUBE_PROVIDER_MACHINETYPE+x} ]; then export KUBE_PROVIDER_MACHINETYPE=Standard_DS2_v2; fi


#Backward compatiblity with previous scripts
if [ ! -z ${AKS_CLUSTER_NAME+x} ]; then export KUBE_CLUSTER_NAME=${AKS_CLUSTER_NAME}; fi
if [ ! -z ${CREATE_AKS_CLUSTER+x} ]; then export KUBE_CREATE_CLUSTER=${CREATE_AKS_CLUSTER}; fi
if [ ! -z ${DELETE_AKS_CLUSTER+x} ]; then export KUBE_DELETE_CLUSTER=${DELETE_AKS_CLUSTER}; fi


source ${COMMON_DIR}/common-login.sh
echo login.sh KUBE_NAMESPACE ${KUBE_NAMESPACE}

echo Exiting login.sh
