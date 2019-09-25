#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running common-teardown-traefik.sh on cluster ${KUBE_CLUSTER_NAME}

${COMMON_DIR}/common-kubectl-connect.sh

# Configure & Delete traefik service
echo "Deleting traefik ingress controller and service"
cat ${COMMON_DIR}/traefik-dep.yaml | envsubst > ${PWD}/_tmp_traefik-dep.yaml
kubectl delete -f ${PWD}/_tmp_traefik-dep.yaml

# Delete traefik configuration to handle https
echo "Deleting configmap ${INGRESS_NAME}-conf"
kubectl delete configmap ${INGRESS_NAME}-conf

# Delete the certificate and key file
echo "... Deleting TLS key"
kubectl delete secret ${INGRESS_NAME}-cert
rm -f tls.crt tls.key

kubectl delete clusterrolebinding ${INGRESS_NAME}-ingress-controller
kubectl delete clusterrole ${INGRESS_NAME}-ingress-controller
kubectl delete serviceaccount ${INGRESS_NAME}-ingress-controller

echo ${Sout:0:Sx} Exiting common-teardown-traefik.sh on cluster ${KUBE_CLUSTER_NAME} ; ((Sx-=1));export Sx;
