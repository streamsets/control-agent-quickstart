#!/bin/bash
source login.sh

######################
# Create GKE Cluster #
######################

if [ "$KUBE_CREATE_CLUSTER" == "1" ]; then
  # if set, this will also attempt to run the gcloud command to provision a cluster
  gcloud container clusters create "${KUBE_CLUSTER_NAME}" \
    --zone "${KUBE_PROVIDER_GEO}" \
    --machine-type "${KUBE_PROVIDER_MACHINETYPE}" \
    --image-type "COS" \
    --disk-size "100" \
    --num-nodes "$KUBE_NODE_INITIALCOUNT" \
    --network "default" \
    --enable-cloud-logging \
    --enable-cloud-monitoring

  # Make current user cluster owner (not strictly necessary for the remainder of this scirpt to work)
  GCP_IAM_USERNAME=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
  $KUBE_EXEC create clusterrolebinding cluster-admin-binding \
      --clusterrole=cluster-admin \
      --user="$GCP_IAM_USERNAME"

  #Config Kubectl
  kubectl config unset contexts.`kubectl config get-contexts -o name | grep ${KUBE_CLUSTER_NAME}`
  gcloud container clusters get-credentials "${KUBE_CLUSTER_NAME}" \
    --zone "${KUBE_PROVIDER_GEO}" || { echo 'ERROR: Failed to configure kubectl context' ; exit 1; }
  #Subsequent scripts expect Cluster name and kubectl Context name to be the same.
  kubectl config rename-context $(kubectl config current-context) ${KUBE_CLUSTER_NAME}

fi


# Set the namespace


if [ "${KUBE_NAMESPACE}" != "?" ] ; then
  $KUBE_EXEC create namespace ${KUBE_NAMESPACE}
  kubectl config set-context ${KUBE_CLUSTER_NAME} --namespace=${KUBE_NAMESPACE}
fi

${COMMON_DIR}/common-startup-services.sh
