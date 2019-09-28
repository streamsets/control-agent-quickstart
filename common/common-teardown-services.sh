#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running common-teardown-services.sh on cluster ${KUBE_CLUSTER_NAME}

${COMMON_DIR}/common-kubectl-connect.sh

######################
# Initialize
######################

${COMMON_DIR}/common-teardown-services-agent.sh


if [ ! -z "${SCH_FWRULE_UTIL}" ] ; then
  #sch_agent_ip="`cat egress-${SCH_AGENT_NAME}-ips.txt`"
  while read egress_ip; do
    echo ... calling firewall utility script: ${COMMON_DIR}/${SCH_FWRULE_UTIL} remove ${egress_ip}
    ${COMMON_DIR}/${SCH_FWRULE_UTIL} remove ${egress_ip} ||  echo "ERROR - Call failed to firewall utility script: ${COMMON_DIR}/${SCH_FWRULE_UTIL}"
  done <egress-${SCH_AGENT_NAME}-ips.txt
  rm -f egress-${SCH_AGENT_NAME}-ips.txt
fi

$KUBE_EXEC delete rolebinding streamsets-agent
$KUBE_EXEC delete role streamsets-agent
$KUBE_EXEC delete serviceaccount streamsets-agent
$KUBE_EXEC delete clusterrolebinding cluster-admin-binding

echo ${Sout:0:Sx} Exiting common-teardown-services.sh on cluster ${KUBE_CLUSTER_NAME} ; ((Sx-=1));export Sx;
