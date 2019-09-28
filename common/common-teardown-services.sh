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

if [ ! -z "${SCH_FWRULE_UTIL}" ] ; then
  #sch_agent_ip="`cat egress-${SCH_AGENT_NAME}-ips.txt`"
  while read egress_ip; do
    echo ... calling firewall utility script: ${COMMON_DIR}/${SCH_FWRULE_UTIL} remove ${egress_ip}
    ${COMMON_DIR}/${SCH_FWRULE_UTIL} remove ${egress_ip} ||  echo "ERROR - Call failed to firewall utility script: ${COMMON_DIR}/${SCH_FWRULE_UTIL}"
  done <egress-${SCH_AGENT_NAME}-ips.txt
  rm -f egress-${SCH_AGENT_NAME}-ips.txt
fi

#echo Deconfigure Kubernetes
#echo ... configuring kubectl
#aws eks --region ${AWS_REGION} update-kubeconfig --name "${KUBE_CLUSTER_NAME}"

#TODO Not necessary if cluster being destroyed
kubectl delete rolebinding streamsets-agent
kubectl delete role streamsets-agent
kubectl delete serviceaccount streamsets-agent
kubectl delete clusterrolebinding cluster-admin-binding

#kubectl delete namespace ${KUBE_NAMESPACE}
#echo "Deleted Namespace ${KUBE_NAMESPACE}"

echo ${Sout:0:Sx} Exiting common-teardown-services.sh on cluster ${KUBE_CLUSTER_NAME} ; ((Sx-=1));export Sx;
