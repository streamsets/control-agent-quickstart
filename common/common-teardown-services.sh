#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running common-teardown-services.sh on cluster ${KUBE_CLUSTER_NAME}

${COMMON_DIR}/common-kubectl-connect.sh

######################
# Initialize
######################

#TODO Change to delete all agents on cluster
#for i in agent-${KUBE_CLUSTER_NAME}*.id; do
i=agent-${SCH_AGENT_NAME}.id
    #[ -f "$i" ] || break # break if zero matches
    suffix=".id";
    basename=${i%$suffix}; #Remove suffix
    prefix="agent-${KUBE_CLUSTER_NAME}-pa";
    agentnamesuffix=${basename#$prefix}; #Remove prefix
    echo Deleting agent suffix $agentnamesuffix;
    ${COMMON_DIR}/common-teardown-services-agent.sh $agentnamesuffix
#done


#echo Deconfigure Kubernetes
#echo ... configuring kubectl
#aws eks --region ${AWS_REGION} update-kubeconfig --name "${KUBE_CLUSTER_NAME}"

#TODO Not necessary if cluster being destroyed
kubectl delete rolebinding streamsets-agent --namespace=${KUBE_NAMESPACE}
kubectl delete role streamsets-agent --namespace=${KUBE_NAMESPACE}
kubectl delete serviceaccount streamsets-agent --namespace=${KUBE_NAMESPACE}
kubectl delete clusterrolebinding cluster-admin-binding

#kubectl delete namespace ${KUBE_NAMESPACE}
#echo "Deleted Namespace ${KUBE_NAMESPACE}"

echo ${Sout:0:Sx} Exiting common-teardown-services.sh on cluster ${KUBE_CLUSTER_NAME} ; ((Sx-=1));export Sx;
