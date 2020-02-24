#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running common-startup-services.sh on cluster ${KUBE_CLUSTER_NAME}

########################################################################
# Set the namespace
########################################################################
if [ "${KUBE_NAMESPACE}" != "?" ] ; then
  echo "Creating namespace ${KUBE_NAMESPACE}"
  $KUBE_EXEC create namespace ${KUBE_NAMESPACE} #|| { echo 'ERROR: Failed to create namespace in Kubernetes' ; exit 1; }
  $KUBE_EXEC config set-context ${KUBE_CLUSTER_NAME} --namespace=${KUBE_NAMESPACE} || { echo 'ERROR: Failed to update default namespace in kubectl' ; exit 1; }
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
  ipfile="${KUBE_CLUSTER_NAME}-egress-ips.txt"

  nodeEgressIPs=$($KUBE_EXEC get nodes -o jsonpath="{.items[*].status.addresses[?(@.type=='ExternalIP')].address}")
  for egressIP in $nodeEgressIPs ; do
    echo "$egressIP" >> ${ipfile}
    echo Node ip is ${egressIP}
  done

  if [[ $(cat ${ipfile} | wc -l) == 0 ]]; then
    echo "... Kubernetes implementation does not record egress IPs in Node description.  Will deploy pods to discover IPs.  This may take a few minutes."
    nodes=$($KUBE_EXEC get nodes -o jsonpath="{.items[*].metadata.name}")
    for node_host in $nodes ; do

      while true ; do
        node_ip=$($KUBE_EXEC run -it caq-discovery-pod --restart=Never --image=busybox --overrides='{ "apiVersion": "v1", "spec": { "nodeSelector": { "kubernetes.io/hostname": "'${node_host}'" } } }' -- sh -c 'wget -qO- ifconfig.me')
        $KUBE_EXEC delete pod caq-discovery-pod
        if [[ $node_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
          if [ $node_ip != 0.0.0.0 ] ; then
            break
          fi
        fi
        echo "... Bad IP Address [] from node ${node_host}.  Will try again. "
      done
      echo ... Node ${node_host} uses egress IP $node_ip
      echo ${node_ip} >> ${ipfile}
    done
  fi

  egress_ips=""
  while read egress_ip; do
    egress_ips+="${egress_ip},"
  done <${ipfile}

  echo egress_ips $egress_ips
  if [ ! -z "${egress_ips}" ]; then
    egress_ip=${egress_ips::-1}
    echo ... calling firewall utility script: ${COMMON_DIR}/${SCH_FWRULE_UTIL} add ${egress_ips}
    ${COMMON_DIR}/${SCH_FWRULE_UTIL} add ${egress_ips} ||  { echo "ERROR - Call failed to firewall utility script: ${COMMON_DIR}/${SCH_FWRULE_UTIL}" ; exit 1; }
  else
    echo -e "\e[33mWARNING: Was unable to retrieve egress IPs for nodes.  You will need to and them manually.\e[0m"
  fi
fi

#######################
# Setup Control Agent #
#######################
${COMMON_DIR}/common-startup-services-agent.sh

echo ${Sout:0:Sx} Exiting common-startup-services.sh on cluster ${KUBE_CLUSTER_NAME} ; ((Sx-=1));export Sx;
