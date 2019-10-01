#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running common-teardown-services.sh on cluster ${KUBE_CLUSTER_NAME}

${COMMON_DIR}/common-kubectl-connect.sh

######################
# Initialize
######################

${COMMON_DIR}/common-teardown-services-agent.sh


if [ ! -z "${SCH_FWRULE_UTIL}" ] ; then
  ipfile="egress-${SCH_AGENT_NAME}-ips.txt"
  if [ -f "${ipfile}" ]; then
    egress_ips=""
    while read egress_ip; do
      egress_ips+="${egress_ip},"
    done <${ipfile}

    echo egress_ips $egress_ips
    if [ ! -z "${egress_ips}" ]; then
      egress_ip=${egress_ips::-1}
      echo ... calling firewall utility script: ${COMMON_DIR}/${SCH_FWRULE_UTIL} remove ${egress_ips}
      ${COMMON_DIR}/${SCH_FWRULE_UTIL} remove ${egress_ips} ||  echo "ERROR - Call failed to firewall utility script: ${COMMON_DIR}/${SCH_FWRULE_UTIL}"
    else
      echo -e "\e[33mWARNING: File ${ipfile} was empty.  Will not remove node addresses from Firewall rule.  You may need to remove them manually.\e[0m"
    fi
    rm -f ${ipfile}
  else
    echo -e "\e[33mWARNING: File ${ipfile} not found.  Will not remove node addresses from Firewall rule.  You may need to remove them manually.\e[0m"
  fi

fi

$KUBE_EXEC delete clusterrolebinding cluster-admin-binding

echo ${Sout:0:Sx} Exiting common-teardown-services.sh on cluster ${KUBE_CLUSTER_NAME} ; ((Sx-=1));export Sx;
