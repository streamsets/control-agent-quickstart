#!/bin/bash
echo Setting Namespace on Kubectl Context
kubectl config set-context $(kubectl config current-context) --namespace=${KUBE_NAMESPACE} || { echo 'ERROR: Failed to set kubectl context' ; exit 1; }



if [ "$SCH_DEPLOYMENT_TYPE" == "AUTHORING" ]; then

    ####################################
    # Setup Traefik Ingress Controller #
    ####################################
    echo ... create serviceaccount
    kubectl create serviceaccount traefik-ingress-controller || { echo 'ERROR: Failed to create serviceaccount in Kubernetes' ; exit 1; }

    echo ... create clusterrole
    kubectl create clusterrole traefik-ingress-controller \
        --verb=get,list,watch \
        --resource=endpoints,ingresses.extensions,services,secrets \
        || { echo 'ERROR: Failed to create clusterrole in Kubernetes' ; exit 1; }
    echo ... create clusterrolebinding
    kubectl create clusterrolebinding traefik-ingress-controller \
        --clusterrole=traefik-ingress-controller \
        --serviceaccount=${KUBE_NAMESPACE}:traefik-ingress-controller \
        || { echo 'ERROR: Failed to create clusterrolebinding in Kubernetes' ; exit 1; }
    echo Running common-startup-services.sh on cluster ${KUBE_CLUSTER_NAME}

    echo Setup Traefik Ingress Controller
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
    kubectl create secret generic traefik-cert \
        --from-file=tls.crt \
        --from-file=tls.key \
        || { echo 'ERROR: Failed to create secret for certificate in Kubernetes' ; exit 1; }

    # 2. Create traefik configuration to handle https
    echo ... create configmap
    kubectl create configmap traefik-conf --from-file=${COMMON_DIR}/traefik.toml || { echo 'ERROR: Failed to create configmap in Kubernetes' ; exit 1; }

    # 3. Configure & create traefik service
    #TODO We just need to wait for loadBalancer.  IP not needed write now.  EKS does not provide ip address and will resolve to null anyway.
    echo ... create traefik service
    kubectl create -f ${COMMON_DIR}/traefik-dep.yaml --namespace=${KUBE_NAMESPACE} || { echo 'ERROR: Failed to traefik service in Kubernetes' ; exit 1; }

    # 4. Wait for an external endpoint to be assigned
    echo ... wait for traefik external ip address
    external_ip=""
    while [ -z $external_ip ]; do
        sleep 10
        #external_ip=$(kubectl get svc traefik-ingress-service -o json | jq -r 'select(.status.loadBalancer.ingress != null) | .status.loadBalancer.ingress[].ip')
        external_ip=$(kubectl get svc traefik-ingress-service -o json | jq -r 'select(.status.loadBalancer.ingress != null) | .status.loadBalancer.ingress[].hostname')
    done
    echo "External Endpoint to Access Authoring SDC : ${external_ip}\n"

fi

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

if [ "$SCH_DEPLOYMENT_TYPE" == "AUTHORING" ]; then

    echo ... create service and ingress for Authoring SDC
    # 1. Create Authoring SDC Service and Ingress
    kubectl create -f ${COMMON_DIR}/authoring-sdc-svc.yaml  || { echo 'ERROR: Failed to create service and ingress for SDC instance' ; exit 1; }

fi

#######################
# Setup Control Agent #
#######################
${COMMON_DIR}/common-startup-services-agent.sh 01

echo Exiting common-startup-services.sh on cluster ${KUBE_CLUSTER_NAME}
