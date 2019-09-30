#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running gcp-firewall-manager.sh

# Print usage
usage() {
  echo -n "Control Agent Quickstart usage:

    $ ./caq  [ACTION] [IP]

        ACTION:
          add               Create K8s cluster and create configuration in SCH
          remove            Create configuration in SCH

"
}

echo debug parameters $@

if [ $# -eq 0 ] ; then
    echo "ERROR - Must supply an action."; usage ; exit 1
else
      FIREWALL_ACTION=$1;shift
fi

if [ $# -eq 0 ] ; then
    echo "ERROR - Must supply an IP address."; usage ; exit 1
else
    IPADRESS=$1;shift
fi

case $FIREWALL_ACTION in
  add)

    echo ... Adding external IP to SCH firewall

    sch_fwrule_sourcranges=$(gcloud compute firewall-rules describe  ${SCH_FWRULE_NAME} --format='value[](sourceRanges)')
    sch_fwrule_sourcranges=${sch_fwrule_sourcranges//;/,}
    gcloud compute firewall-rules update ${SCH_FWRULE_NAME} --source-ranges=${sch_fwrule_sourcranges},${IPADRESS}
    ;;
  remove)
    echo ... Removing external IP from SCH firewall
    sch_fwrule_sourcranges=$(gcloud compute firewall-rules describe  ${SCH_FWRULE_NAME} --format='value[](sourceRanges)')
    IFS=';' ; sch_fwrule_sourcranges_array=($sch_fwrule_sourcranges)
    ipaddress_array=(${IPADRESS})
    sch_fwrule_sourcranges_array=( "${sch_fwrule_sourcranges_array[@]/$ipaddress_array}" )
    sch_fwrule_sourcranges=$(IFS=, ; echo "${sch_fwrule_sourcranges_array[*]}")
    sch_fwrule_sourcranges=${sch_fwrule_sourcranges//;/,}
    sch_fwrule_sourcranges=${sch_fwrule_sourcranges//,,/,}
    gcloud compute firewall-rules update ${SCH_FWRULE_NAME} --source-ranges=${sch_fwrule_sourcranges}
    ;;
  *)
    echo "ERROR - Invalid action: '${FIREWALL_ACTION}'"; usage ; exit 1 ;;

esac

echo ${Sout:0:Sx} Exiting gcp-firewall-manager.sh ; ((Sx-=1));export Sx;
