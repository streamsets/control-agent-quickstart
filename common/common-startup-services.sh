#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running common-startup-services.sh on cluster ${KUBE_CLUSTER_NAME}

########################################################################
# Set the namespace
########################################################################
if [ "${KUBE_NAMESPACE}" != "?" ] ; then
  echo "Creating namespace ${KUBE_NAMESPACE}"
  $KUBE_EXEC create namespace ${KUBE_NAMESPACE} || { echo 'ERROR: Failed to create namespace in Kubernetes' ; exit 1; }
  kubectl config set-context ${KUBE_CLUSTER_NAME} --namespace=${KUBE_NAMESPACE} || { echo 'ERROR: Failed to update default namespace in kubectl' ; exit 1; }
fi

########################################################################
# Connect kubectl
########################################################################
source ${COMMON_DIR}/common-kubectl-connect.sh

########################################################################
# Update SCH Firewall (if any)
########################################################################
if [ ! -z "${SCH_FWRULE_UTIL}" ] ; then
  echo Adding Nodes to SCH Firewall
  nodeEgressIPs=$($KUBE_EXEC get nodes -o jsonpath="{.items[*].status.addresses[?(@.type=='ExternalIP')].address}")
  for egressIP in $nodeEgressIPs ; do
    echo "$egressIP" >> ${KUBE_CLUSTER_NAME}-egress-ips.txt
    echo Node ip is ${egressIP}
  done

  echo nodeEgressIPs comma delimted ${nodeEgressIPs[*]// /,}
  echo Calling firewall utility script: ${COMMON_DIR}/${SCH_FWRULE_UTIL} add "${nodeEgressIPs[*]// /,}"
  ${COMMON_DIR}/${SCH_FWRULE_UTIL} add ${nodeEgressIPs[*]// /,} ||  echo "ERROR - Call failed to firewall utility script: ${COMMON_DIR}/${SCH_FWRULE_UTIL}"
fi

#######################
# Setup Control Agent #
#######################
${COMMON_DIR}/common-startup-services-agent.sh

echo ${Sout:0:Sx} Exiting common-startup-services.sh on cluster ${KUBE_CLUSTER_NAME} ; ((Sx-=1));export Sx;
