#!/bin/bash
source login.sh

######################
# Create GKE Cluster #
######################

if [ -n "$KUBE_CREATE_CLUSTER" ]; then
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

  gcloud container clusters get-credentials "${KUBE_CLUSTER_NAME}" \
    --zone "${KUBE_PROVIDER_GEO}" || { echo 'ERROR: Failed to configure kubectl context' ; exit 1; }

  #Subsequent scripts expect Cluster name and kubectl Context name to be the same.
  kubectl config rename-context $(kubectl config current-context) ${KUBE_CLUSTER_NAME} || { echo 'ERROR: Failed to rename kubectl context' ; exit 1; }

fi

# Set the namespace
kubectl create namespace ${KUBE_NAMESPACE}
kubectl config set-context ${KUBE_CLUSTER_NAME} --namespace=${KUBE_NAMESPACE}

GCP_IAM_USERNAME=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user="$GCP_IAM_USERNAME"

${COMMON_DIR}/common-startup-services.sh
