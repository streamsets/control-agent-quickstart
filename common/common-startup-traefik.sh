#!/bin/bash
echo Running common-startup-traefik.sh on cluster ${KUBE_CLUSTER_NAME}

${COMMON_DIR}/common-kubectl-connect.sh

####################################
# Setup Traefik Ingress Controller #
####################################
echo ... create serviceaccount
kubectl create serviceaccount ${INGRESS_NAME}-ingress-controller || { echo 'ERROR: Failed to create serviceaccount in Kubernetes' ; exit 1; }

echo ... create clusterrole
kubectl create clusterrole ${INGRESS_NAME}-ingress-controller \
    --verb=get,list,watch \
    --resource=endpoints,ingresses.extensions,services,secrets \
    || { echo 'ERROR: Failed to create clusterrole in Kubernetes' ; exit 1; }
echo ... create clusterrolebinding
kubectl create clusterrolebinding ${INGRESS_NAME}-ingress-controller \
    --clusterrole=${INGRESS_NAME}-ingress-controller \
    --serviceaccount=${KUBE_NAMESPACE}:${INGRESS_NAME}-ingress-controller \
    || { echo 'ERROR: Failed to create clusterrolebinding in Kubernetes' ; exit 1; }
echo Running common-startup-services.sh on cluster ${KUBE_CLUSTER_NAME}

echo Setup ${INGRESS_NAME} Ingress Controller
echo ... generate self signed certificate
# 1. Generate self signed certificate and create a secret
openssl req -newkey rsa:2048 \
    -nodes \
    -keyout tls.key \
    -x509 \
    -days 365 \
    -out tls.crt \
    -subj "/C=US/ST=California/L=San Francisco/O=My Company/CN=mycompany.com" \
    || { echo 'ERROR: Failed to generate self-signed certificate' ; exit 1; }
kubectl create secret generic ${INGRESS_NAME}-cert \
    --from-file=tls.crt \
    --from-file=tls.key \
    || { echo 'ERROR: Failed to create secret for certificate in Kubernetes' ; exit 1; }

echo SCH_DEPLOYMENT_LBPORT ${SCH_DEPLOYMENT_LBPORT}

# 2. Create traefik configuration to handle https
echo ... create configmap
cat ${COMMON_DIR}/traefik.toml | envsubst > ${PWD}/_tmp_traefik.toml
kubectl create configmap ${INGRESS_NAME}-conf --from-file=traefik.toml=${PWD}/_tmp_traefik.toml || { echo 'ERROR: Failed to create configmap in Kubernetes' ; exit 1; }

# 3. Configure & create traefik service
#TODO We just need to wait for loadBalancer.  IP not needed write now.  EKS does not provide ip address and will resolve to null anyway.
echo ... create traefik service
cat ${COMMON_DIR}/traefik-dep.yaml | envsubst > ${PWD}/_tmp_traefik-dep.yaml
kubectl create -f ${PWD}/_tmp_traefik-dep.yaml --namespace=${KUBE_NAMESPACE} || { echo 'ERROR: Failed to traefik service in Kubernetes' ; exit 1; }

# 4. Wait for an external endpoint to be assigned
#echo ... wait for traefik external ip address
#external_ip=""
#while [ -z $external_ip ]; do
#    sleep 10
#    #external_ip=$(kubectl get svc ${INGRESS_NAME}-ingress-service -o json | jq -r 'select(.status.loadBalancer.ingress != null) | .status.loadBalancer.ingress[].ip')
#    external_ip=$(kubectl get svc ${INGRESS_NAME}-ingress-service -o json | jq -r 'select(.status.loadBalancer.ingress != null) | .status.loadBalancer.ingress[].hostname')
#done
#echo "External Endpoint to Access Authoring SDC : ${external_ip}\n"

echo Exiting common-startup-traefik.sh on cluster ${KUBE_CLUSTER_NAME}
