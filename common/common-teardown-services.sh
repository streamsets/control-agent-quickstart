#!/bin/bash
source ${COMMON_DIR}/common-login.sh

echo Setting Namespace on Kubectl Context
kubectl config set-context $(kubectl config current-context) --namespace=${KUBE_NAMESPACE} || { echo 'ERROR: Failed to set kubectl context' ; exit 1; }

######################
# Initialize
######################

: ${KUBE_CLUSTER_NAME:="streamsets-quickstart"}
if [ -z ${SCH_AGENT_NAME+x} ]; then export SCH_AGENT_NAME=${KUBE_CLUSTER_NAME}-schagent01; fi

#TODO Change to delete all agents on cluster
for i in agent-${KUBE_CLUSTER_NAME}*.id; do
    [ -f "$i" ] || break # break if zero matches
    suffix=".id";
    basename=${i%$suffix}; #Remove suffix
    prefix="agent-${KUBE_CLUSTER_NAME}-schagent";
    agentnamesuffix=${basename#$prefix}; #Remove prefix
    echo Deleting agent suffix $agentnamesuffix;
    ${COMMON_DIR}/common-teardown-services-agent.sh $agentnamesuffix
done


#echo Deconfigure Kubernetes
#echo ... configuring kubectl
#aws eks --region ${AWS_REGION} update-kubeconfig --name "${KUBE_CLUSTER_NAME}"

# Configure & Delete traefik service
kubectl delete -f traefik-dep.yaml
echo "Deleted traefik ingresskub controller and service"

# Delete traefik configuration to handle https
kubectl delete configmap traefik-conf
echo "Deleted configmap traefik-conf"

echo ... Delete Authoring SDC Service
kubectl delete -f authoring-sdc-svc.yaml
echo "... Deleted Authoring sdc service"


# Delete the certificate and key file
kubectl delete secret traefik-cert
rm -f tls.crt tls.key
echo "... Deleted TLS key"

#TODO Not necessary if cluster being destroyed
kubectl delete rolebinding streamsets-agent --namespace=${KUBE_NAMESPACE}
kubectl delete role streamsets-agent --namespace=${KUBE_NAMESPACE}
kubectl delete serviceaccount streamsets-agent --namespace=${KUBE_NAMESPACE}
kubectl delete clusterrolebinding traefik-ingress-controller
kubectl delete clusterrole traefik-ingress-controller
kubectl delete serviceaccount traefik-ingress-controller
kubectl delete clusterrolebinding cluster-admin-binding

#kubectl delete namespace ${KUBE_NAMESPACE}
#echo "Deleted Namespace ${KUBE_NAMESPACE}"
