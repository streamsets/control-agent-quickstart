#!/bin/bash
echo Running `basename "$0"`

source login.sh

${COMMON_DIR}/common-teardown-services.sh

if [ -n "$KUBE_DELETE_CLUSTER" ]; then
  gcloud container clusters delete ${KUBE_CLUSTER_NAME} --zone "${KUBE_PROVIDER_GEO}"
fi

#Clean up kubectl config
kubectl config unset users.`kubectl config view -o jsonpath='{.users[*].name}' | tr " " "\n" | grep ${KUBE_CLUSTER_NAME}`
kubectl config unset clusters.`kubectl config get-clusters | grep ${KUBE_CLUSTER_NAME}`
kubectl config unset contexts.`kubectl config get-contexts -o name | grep ${KUBE_CLUSTER_NAME}`
