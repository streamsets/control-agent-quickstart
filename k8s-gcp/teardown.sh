#!/bin/bash
echo Running `basename "$0"`

source login.sh

${COMMON_DIR}/common-teardown-services.sh

if [ "$KUBE_DELETE_CLUSTER" == "1" ]; then
  gcloud -q container clusters delete ${KUBE_CLUSTER_NAME} --zone "${KUBE_PROVIDER_GEO}"
fi

${COMMON_DIR}/common-kubectl-cleanup.sh
