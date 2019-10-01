#!/bin/bash
((Sx+=1));export Sx; echo ${Sin:0:Sx} Running common-login.sh

COMMON_DIR="`dirname \"$0\"`"                 # relative
if [ -z "$COMMON_DIR" ] ; then
  echo "ERROR - For some reason, the path is not accessible to the script (e.g. permissions re-evaled after suid)"
  exit 1  # fail
fi
COMMON_DIR="${COMMON_DIR}/../common"
COMMON_DIR="`( cd \"$COMMON_DIR\" && pwd )`"  # absolutized and normalized
export COMMON_DIR

#----------------------------------------------------------
# Contain variable and checks that are common to all SCH/K8S environemnt setups
#----------------------------------------------------------

function show_usage {
  echo "\nVariables can be exported or set on the command line as shown below."
  echo 'SCH_ORG="myorg" SCH_USER="user@myorg" SCH_PASSWORD="mypassword" KUBE_NAMESPACE="agent-quickstart2" ./startup.sh'
  echo '-----------------------------------------------------------------------'
}

if [ -z "$(which jq)" ]; then
  echo "This script requires the 'jq' utility."
  echo "Please install it from https://stedolan.github.io/jq/"
  echo "or your favorite package manager."
  echo "On macOS you can install it via Homebrew using 'brew install jq'"
  exit 1
fi

: ${KUBE_EXEC:=kubectl}
if [ -z "$(which ${KUBE_EXEC})" ]; then
  echo "ERROR: Unable to find the executable ${KUBE_EXEC}, which is defined by variable KUBE_EXEC, on the PATH."
  echo "This script requires the 'kubectl' or utility of an equivalent kube."
  echo "Please install it via one of the methods described here:"
  echo "https://kubernetes.io/docs/tasks/tools/install-kubectl/"
  exit 1
fi

: ${KUBE_NAMESPACE:=streamsets}
export KUBE_NAMESPACE

if [ "${KUBE_NAMESPACE}" != "?" ] ; then
  KUBE_EXEC="${KUBE_EXEC} --namespace=${KUBE_NAMESPACE}"
fi
export KUBE_EXEC

KUBE_NAMESPACE_ACTUAL=$(kubectl config view --minify --output 'jsonpath={..namespace}')
export KUBE_NAMESPACE_ACTUAL

if [ -z "$(which envsubst)" ]; then
  echo "This script requires the 'envsubst' utility. See:"
  echo "https://command-not-found.com/envsubt"
  exit 1
fi

if [ -z "$SCH_ORG" ]; then
  show_usage
  echo "Please set SCH_ORG to your organization name."
  echo "This is the part of your login after the '@' symbol"
  exit 1
fi

if [ -z "$SCH_USER" ]; then
  show_usage
  echo "Please set SCH_USER to your username in the form 'user@org'"
  exit 1
fi
#TODO veify user's org matches $SCH_ORG

if [ -z "$SCH_PASSWORD" ]; then
  show_usage
  echo "Please set SCH_PASSWORD to your StreamSets Control Hub password"
  exit 1
fi


: ${SCH_URL:=https://cloud.streamsets.com}
sch_authentication=$(curl -s -X POST -d "{\"userName\":\"${SCH_USER}\", \"password\": \"${SCH_PASSWORD}\"}" ${SCH_URL}/security/public-rest/v1/authentication/login --header "Content-Type:application/json" --header "X-Requested-By:SDC" -c - )
ret=$?
if [ $ret -eq 35 ]; then
  echo "SSL connect Error. The SSL handshaking failed."
  echo "Does this SCH instance support HTTPS?"
  exit 1
fi
export SCH_TOKEN=$(echo $sch_authentication | sed -n '/SS-SSO-LOGIN/p' | perl -lane 'print $F[$#F]')
if [ -z "$SCH_TOKEN" ]; then
  echo "Failed to authenticate with SCH :("
  echo "Please check your username, password, and organization name."
  exit 1
fi

: ${SDC_DOCKER_IMAGE:=streamsets/datacollector}
export SDC_DOCKER_IMAGE

: ${SDC_DOCKER_TAG:=latest}
export SDC_DOCKER_TAG

: ${SDC_CPUS:=2}
export SDC_CPUS

: ${SDC_REPLICAS:=1}
export SDC_REPLICAS

: ${SDC_REPLICAS_MIN:=1}
export SDC_REPLICAS_MIN

: ${SDC_REPLICAS_MAX:=10}
export SDC_REPLICAS_MAX

: ${SDC_REPLICAS_CPU_THRESHOLD:=50}
export SDC_REPLICAS_CPU_THRESHOLD


: ${SCH_AGENT_DOCKER_TAG:=latest}
export SCH_AGENT_DOCKER_TAG

: ${KUBE_CLUSTER_NAME:="streamsets-quickstart"}
export KUBE_CLUSTER_NAME

if [ -z "${KUBE_CONTEXT_NAME}" ] ; then
  KUBE_CONTEXT_NAME=${KUBE_CLUSTER_NAME}
fi
export KUBE_CONTEXT_NAME
echo KUBE_CONTEXT_NAME $KUBE_CONTEXT_NAME

if [ -z ${SCH_AGENT_NAME+x} ]; then export SCH_AGENT_NAME=${KUBE_CLUSTER_NAME}-pa01; fi
export SCH_AGENT_NAME

if [ -z ${SCH_DEPLOYMENT_NAME+x} ]; then export SCH_DEPLOYMENT_NAME=${SCH_AGENT_NAME}-deploy01; fi
export SCH_DEPLOYMENT_NAME

: ${SCH_DEPLOYMENT_TYPE:=AUTHORING}
SCH_DEPLOYMENT_TYPE=$(echo "${SCH_DEPLOYMENT_TYPE}" | tr '[:lower:]' '[:upper:]')
export SCH_DEPLOYMENT_TYPE

: ${INGRESS_PORT_HTTP:=80}
export INGRESS_PORT_HTTP

: ${INGRESS_PORT_HTTPS:=443}
export INGRESS_PORT_HTTPS

if [ -z "${KUBE_NODE_INITIALCOUNT}" ] ; then
  if [ "${SCH_DEPLOYMENT_TYPE}" == "AUTHORING" ] ; then
    export KUBE_NODE_INITIALCOUNT=1
  else
    export KUBE_NODE_INITIALCOUNT=3
  fi
fi

if [ -z ${INGRESS_NAME+x} ]; then export INGRESS_NAME=${SCH_DEPLOYMENT_NAME}-traefik; fi
export INGRESS_NAME

if [ ! -z "${SCH_FWRULE_UTIL}" ] ; then
  echo Firewall Rule management utlity is enabled: ${SCH_FWRULE_UTIL}
  if [ -z ${SCH_FWRULE_NAME} ]; then
    echo "Please set SCH_FWRULE_NAME to the name of the Firewall Rule to be managed."
    exit 1
  fi
fi

echo K8S Cluster Name: ${KUBE_CLUSTER_NAME}
echo K8S Namespace: ${KUBE_NAMESPACE}
echo K8S Initial Node Count $KUBE_NODE_INITIALCOUNT
echo Agent name: ${SCH_AGENT_NAME}

export Sin=">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
export Sout="<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"

echo ${Sout:0:Sx} Exiting common-login.sh ; ((Sx-=1));export Sx;
