#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running common-startup-services.sh on cluster ${KUBE_CLUSTER_NAME}

${COMMON_DIR}/common-kubectl-connect.sh

########################################################################
# Setup Service Account with roles to read required kubernetes objects #
########################################################################

# Update SCH Firewall (if any)
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
${COMMON_DIR}/common-startup-services-agent.sh 01

echo ${Sout:0:Sx} Exiting common-startup-services.sh on cluster ${KUBE_CLUSTER_NAME} ; ((Sx-=1));export Sx;
