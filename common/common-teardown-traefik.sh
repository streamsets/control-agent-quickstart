#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running common-teardown-traefik.sh on cluster ${KUBE_CLUSTER_NAME}

${COMMON_DIR}/common-kubectl-connect.sh

# Configure & Delete traefik service
echo "Deleting traefik ingress controller and service"
cat ${COMMON_DIR}/traefik-dep.yaml | envsubst > ${PWD}/_tmp_traefik-dep.yaml
$KUBE_EXEC delete -f ${PWD}/_tmp_traefik-dep.yaml

# Delete traefik configuration to handle https
echo "Deleting configmap ${INGRESS_NAME}-conf"
$KUBE_EXEC delete configmap ${INGRESS_NAME}-conf

# Delete the certificate and key file
echo "... Deleting TLS key"
$KUBE_EXEC delete secret ${INGRESS_NAME}-cert
rm -f tls.crt tls.key

$KUBE_EXEC delete rolebinding ${INGRESS_NAME}-ingress-controller
$KUBE_EXEC delete role ${INGRESS_NAME}-ingress-controller
$KUBE_EXEC delete serviceaccount ${INGRESS_NAME}-ingress-controller

echo ${Sout:0:Sx} Exiting common-teardown-traefik.sh on cluster ${KUBE_CLUSTER_NAME} ; ((Sx-=1));export Sx;
