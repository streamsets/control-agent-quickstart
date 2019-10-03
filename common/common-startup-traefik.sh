#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running common-startup-traefik.sh on cluster ${KUBE_CLUSTER_NAME}

source ${COMMON_DIR}/common-kubectl-connect.sh

####################################
# Setup Traefik Ingress Controller #
####################################
echo ... create serviceaccount
$KUBE_EXEC create serviceaccount ${INGRESS_NAME}-ingress-controller || { echo 'ERROR: Failed to create serviceaccount in Kubernetes' ; exit 1; }

echo ... create role
$KUBE_EXEC create role ${INGRESS_NAME}-ingress-controller \
    --verb=get,list,watch \
    --resource=endpoints,ingresses.extensions,services,secrets \
    || { echo 'ERROR: Failed to create role in Kubernetes' ; exit 1; }
echo ... create rolebinding
$KUBE_EXEC create rolebinding ${INGRESS_NAME}-ingress-controller \
    --role=${INGRESS_NAME}-ingress-controller \
    --serviceaccount=${KUBE_NAMESPACE_CURRENT}:${INGRESS_NAME}-ingress-controller \
    || { echo 'ERROR: Failed to create rolebinding in Kubernetes' ; exit 1; }
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
$KUBE_EXEC create secret generic ${INGRESS_NAME}-cert \
    --from-file=tls.crt \
    --from-file=tls.key \
    || { echo 'ERROR: Failed to create secret for certificate in Kubernetes' ; exit 1; }

# 2. Create traefik configuration to handle https
echo ... create configmap
cat ${COMMON_DIR}/traefik.toml | envsubst > ${PWD}/_tmp_traefik.toml
$KUBE_EXEC create configmap ${INGRESS_NAME}-conf --from-file=traefik.toml=${PWD}/_tmp_traefik.toml || { echo 'ERROR: Failed to create configmap in Kubernetes' ; exit 1; }

# 3. Configure & create traefik service
#TODO We just need to wait for loadBalancer.  IP not needed write now.  EKS does not provide ip address and will resolve to null anyway.
echo ... create traefik service
cat ${COMMON_DIR}/traefik-dep.yaml | envsubst > ${PWD}/_tmp_traefik-dep.yaml
$KUBE_EXEC create -f ${PWD}/_tmp_traefik-dep.yaml || { echo 'ERROR: Failed to traefik service in Kubernetes' ; exit 1; }

echo ${Sout:0:Sx} Exiting common-startup-traefik.sh on cluster ${KUBE_CLUSTER_NAME} ; ((Sx-=1));export Sx;
