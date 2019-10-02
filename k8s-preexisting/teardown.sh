#!/bin/bash
echo Running teardown.sh

source login.sh

${COMMON_DIR}/common-teardown-services.sh

if [ "$KUBE_DELETE_CLUSTER" == "1" ]; then
#
#  gcloud container clusters delete ${KUBE_CLUSTER_NAME} --zone "${KUBE_PROVIDER_GEO}"

  if [ "${KUBE_CONTEXT_NAME}" != "?" ] ; then

    #Clean up kubectl config
    kubectl config unset users.`kubectl config view -o jsonpath='{.users[*].name}' | tr " " "\n" | grep ${KUBE_CLUSTER_NAME}`
    kubectl config unset clusters.`kubectl config get-clusters | grep ${KUBE_CLUSTER_NAME}`
    kubectl config unset contexts.`kubectl config get-contexts -o name | grep ${KUBE_CLUSTER_NAME}`
  fi

fi
