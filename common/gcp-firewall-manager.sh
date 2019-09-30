#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running gcp-firewall-manager.sh
# ==============================================================================
# GCP Firewall Manger
# ------------------
# This script upadtes adds and removes IP addresss from a GCP firewall rule.
# ==============================================================================

# Print usage
usage() {
  echo -n "Control Agent Quickstart usage:

    $ ./caq  [ACTION] [IP]

        ACTION:
          add               Create K8s cluster and create configuration in SCH
          remove            Create configuration in SCH

        IP: Comma delimted list of IP addresses to be processed

"
}

if [ $# -eq 0 ] ; then
    echo "ERROR - Must supply an action."; usage ; exit 1
else
      firewall_action=$1;shift
fi

if [ $# -eq 0 ] ; then
    echo "ERROR - Must supply an IP address."; usage ; exit 1
else
    ipaddress=$1;shift
fi

case $firewall_action in

  add)
    echo "Adding external IP(s) to SCH firewall"

    sch_fwrule_sourcranges=$(gcloud compute firewall-rules describe  ${SCH_FWRULE_NAME} --format='value[](sourceRanges)')
    sch_fwrule_sourcranges=${sch_fwrule_sourcranges//;/,}
    gcloud compute firewall-rules update ${SCH_FWRULE_NAME} --source-ranges=${sch_fwrule_sourcranges},${ipaddress}
    ;;

  remove)
    echo "Removing IP(s)s from SCH firewall"
    #Get Array w/ current cource IPs from Firewall rule
    sch_fwrule_sourcranges=$(gcloud compute firewall-rules describe  ${SCH_FWRULE_NAME} --format='value[](sourceRanges)')
    $(IFS=';' ; sch_fwrule_sourcranges_array=($sch_fwrule_sourcranges))

    for i in ${ipaddress//,/ }
    do
      echo "... Removing $i"
      sch_fwrule_sourcranges_array=( "${sch_fwrule_sourcranges_array[@]/$i}" )
    done

    sch_fwrule_sourcranges=$(IFS=, ; echo "${sch_fwrule_sourcranges_array[*]}")
    gcloud compute firewall-rules update ${SCH_FWRULE_NAME} --source-ranges=${sch_fwrule_sourcranges}
    ;;

  *)
    echo "ERROR - Invalid action: '${firewall_action}'"; usage ; exit 1 ;;

esac

echo ${Sout:0:Sx} Exiting gcp-firewall-manager.sh ; ((Sx-=1));export Sx;
