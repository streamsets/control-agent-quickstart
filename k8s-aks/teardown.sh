#!/bin/bash
echo Running `basename "$0"`

source login.sh

${COMMON_DIR}/common-teardown-services.sh

if [ "$KUBE_DELETE_CLUSTER" == "1" ]; then
  echo Destorying K8s Cluster
  az group delete --name ${AZURE_RESOURCE_GROUP} --yes --verbose
  #--no-wait
fi

${COMMON_DIR}/common-kubectl-cleanup.sh
