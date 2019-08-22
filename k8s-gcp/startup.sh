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
    --zone "${KUBE_PROVIDER_GEO}"

fi

# Set the namespace
kubectl create namespace ${KUBE_NAMESPACE}
kubectl config set-context $(kubectl config current-context) --namespace=${KUBE_NAMESPACE}

GCP_IAM_USERNAME=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user="$GCP_IAM_USERNAME"

${COMMON_DIR}/common-startup-services.sh
