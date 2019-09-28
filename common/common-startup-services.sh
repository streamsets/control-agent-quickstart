#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running common-startup-services.sh on cluster ${KUBE_CLUSTER_NAME}

${COMMON_DIR}/common-kubectl-connect.sh

########################################################################
# Setup Service Account with roles to read required kubernetes objects #
########################################################################

# Update SCF Firewall (if any)
if [ ! -z "${SCH_FWRULE_UTIL}" ] ; then
  echo Adding Nodes to SCH Firewall
  #TODO - This may only work for AWS
  nodeEgressIPs=$(kubectl get nodes -o jsonpath="{.items[*].status.addresses[?(@.type=='ExternalIP')].address}")
  for egressIP in $nodeEgressIPs ; do
    echo "$egressIP" >> egress-${SCH_AGENT_NAME}-ips.txt
    echo Node ip is ${egressIP}
  done

  while read egress_ip; do
    echo "$p"
    echo Calling firewall utility script: ${COMMON_DIR}/${SCH_FWRULE_UTIL} add ${egress_ip}
    ${COMMON_DIR}/${SCH_FWRULE_UTIL} add ${egress_ip} ||  echo "ERROR - Call failed to firewall utility script: ${COMMON_DIR}/${SCH_FWRULE_UTIL}"
  done <egress-${SCH_AGENT_NAME}-ips.txt
fi

echo Setup Agent Service
echo ... create service acount
kubectl create serviceaccount streamsets-agent || { echo 'ERROR: Failed to create serviceaccount in Kubernetes' ; exit 1; }

echo ... create role
kubectl create role streamsets-agent \
    --verb=get,list,create,update,delete,patch \
    --resource=pods,secrets,ingresses,services,horizontalpodautoscalers,replicasets.apps,deployments.apps,replicasets.extensions,deployments.extensions \
    || { echo 'ERROR: Failed to create role in Kubernetes' ; exit 1; }
echo ... create rolebining
kubectl create rolebinding streamsets-agent \
    --role=streamsets-agent \
    --serviceaccount=${KUBE_NAMESPACE}:streamsets-agent \
    || { echo 'ERROR: Failed to create rolebinding in Kubernetes' ; exit 1; }

#######################
# Setup Control Agent #
#######################
${COMMON_DIR}/common-startup-services-agent.sh 01

echo ${Sout:0:Sx} Exiting common-startup-services.sh on cluster ${KUBE_CLUSTER_NAME} ; ((Sx-=1));export Sx;
