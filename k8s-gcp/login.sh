#!/bin/bash
echo Running login.sh

export PROVIDER_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export COMMON_DIR=`echo $(cd ${PROVIDER_DIR}/../common; pwd)`

if [ -z "$(which gcloud)" ]; then
  echo "This script requires the 'gcloud' utility"
  echo "Please install it via one of the methods described here:"
  echo "https://cloud.google.com/sdk/downloads"
  exit 1
fi

if [ -z ${KUBE_PROVIDER_GEO+x} ]; then export KUBE_PROVIDER_GEO="us-central1-a"; fi
if [ -z ${KUBE_PROVIDER_MACHINETYPE+x} ]; then export KUBE_PROVIDER_MACHINETYPE="t3.n1-standard-1"; fi

#Backward compatiblity with previous scripts
if [ ! -z ${GKE_CLUSTER_NAME+x} ]; then export KUBE_CLUSTER_NAME=${GKE_CLUSTER_NAME}; fi
if [ ! -z ${CREATE_GKE_CLUSTER+x} ]; then export KUBE_CREATE_CLUSTER=${CREATE_GKE_CLUSTER}; fi
if [ ! -z ${DELETE_GKE_CLUSTER+x} ]; then export KUBE_DELETE_CLUSTER=${DELETE_GKE_CLUSTER}; fi

source ${COMMON_DIR}/common-login.sh

echo Exiting login.sh
