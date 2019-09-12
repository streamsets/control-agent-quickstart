#!/bin/bash
echo Running common-kubectl-connect.sh

echo "Switching Kubectl to Context (${KUBE_CLUSTER_NAME}) and Namespace (${KUBE_NAMESPACE})"
kubectl config use-context ${KUBE_CLUSTER_NAME} --namespace=${KUBE_NAMESPACE} || { echo 'ERROR: Failed to swtich kubectl context' ; exit 1; }

echo Exiting common-kubectl-connect.sh
