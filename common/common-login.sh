#!/bin/bash
echo Running common-login.sh

echo K8S Cluster Name: ${KUBE_CLUSTER_NAME}
echo K8S Namespace: ${KUBE_NAMESPACE}
echo Agent name: ${SCH_AGENT_NAME}


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

if [ -z "$(which kubectl)" ]; then
  echo "This script requires the 'kubectl' utility."
  echo "Please install it via one of the methods described here:"
  echo "https://kubernetes.io/docs/tasks/tools/install-kubectl/"
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
export SCH_TOKEN=$(curl -s -X POST -d "{\"userName\":\"${SCH_USER}\", \"password\": \"${SCH_PASSWORD}\"}" ${SCH_URL}/security/public-rest/v1/authentication/login --header "Content-Type:application/json" --header "X-Requested-By:SDC" -c - | sed -n '/SS-SSO-LOGIN/p' | perl -lane 'print $F[$#F]')

if [ -z "$SCH_TOKEN" ]; then
  echo "Failed to authenticate with SCH :("
  echo "Please check your username, password, and organization name."
  exit 1
fi

: ${SDC_DOCKER_IMAGE:=streamsets/datacollector}
export SDC_DOCKER_IMAGE

: ${SDC_DOCKER_TAG:=latest}
#: ${SDC_DOCKERTAG:=3.0.0.0}
export SDC_DOCKER_TAG

: ${KUBE_NAMESPACE:=streamsets}
export KUBE_NAMESPACE

: ${KUBE_CLUSTER_NAME:="streamsets-quickstart"}
export KUBE_CLUSTER_NAME

if [ -z ${SCH_AGENT_NAME+x} ]; then export SCH_AGENT_NAME=${KUBE_CLUSTER_NAME}-schagent01; fi
export SCH_AGENT_NAME

echo K8S Cluster Name: ${KUBE_CLUSTER_NAME}
echo K8S Namespace: ${KUBE_NAMESPACE}
echo Agent name: ${SCH_AGENT_NAME}

echo Exiting common-login.sh
