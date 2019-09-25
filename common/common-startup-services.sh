#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running common-startup-services.sh on cluster ${KUBE_CLUSTER_NAME}

${COMMON_DIR}/common-kubectl-connect.sh

########################################################################
# Setup Service Account with roles to read required kubernetes objects #
########################################################################

echo Setup Agent Service
echo ... create service acount
kubectl create serviceaccount streamsets-agent --namespace=${KUBE_NAMESPACE} || { echo 'ERROR: Failed to create serviceaccount in Kubernetes' ; exit 1; }

echo ... create role
kubectl create role streamsets-agent \
    --verb=get,list,create,update,delete,patch \
    --resource=pods,secrets,ingresses,services,horizontalpodautoscalers,replicasets.apps,deployments.apps,replicasets.extensions,deployments.extensions \
    --namespace=${KUBE_NAMESPACE} \
    || { echo 'ERROR: Failed to create role in Kubernetes' ; exit 1; }
echo ... create rolebining
kubectl create rolebinding streamsets-agent \
    --role=streamsets-agent \
    --serviceaccount=${KUBE_NAMESPACE}:streamsets-agent \
    --namespace=${KUBE_NAMESPACE} \
    || { echo 'ERROR: Failed to create rolebinding in Kubernetes' ; exit 1; }

#######################
# Setup Control Agent #
#######################
${COMMON_DIR}/common-startup-services-agent.sh 01

echo ${Sout:0:Sx} Exiting common-startup-services.sh on cluster ${KUBE_CLUSTER_NAME} ; ((Sx-=1));export Sx;
