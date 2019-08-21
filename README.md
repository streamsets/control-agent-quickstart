# control-agent-quickstart

This project provides pre-built scripts to configure Streamsets Control Hub (SCH) to work with various Kubernetes (K8s) providers.  You may use an existing K8s cluster or have the scripts generate a new one.

These configurations are for demonstration purposes only and will require modification for use in a production environment.


## Prerequisites:

1. kubectl
2. jq

*See the individual K8s Provider folders for additional prerequisites.*


## Usage:


### Startup
To launch the quick start with a fresh Kubernetes cluster, run the following command:

1. cd to subfolder for desired k8s provider
2. Run the following command:
~~~
SCH_ORG=<org> SCH_USER=<user>@<org> SCH_PASSWORD=<password> KUBE_CREATE_CLUSTER=1 KUBE_CLUSTER_NAME=<your_cluster_name> ./startup.sh
~~~

To start the services on existing cluster:

1. cd to subfolder for desired k8s provider
2. Run the following command:
~~~
SCH_ORG=<org> SCH_USER=<user>@<org> SCH_PASSWORD=<password> KUBE_CLUSTER_NAME=<your_cluster_name> ./startup-services.sh
~~~


### Teardown

To delete the quick start with AND the Kubernetes cluster, run the following command:

1. cd to subfolder for desired k8s provider
2. Run the following command:
~~~
SCH_ORG=<org> SCH_USER=<user>@<org> SCH_PASSWORD=<password> KUBE_DELETE_CLUSTER=1 KUBE_CLUSTER_NAME=<your_cluster_name> ./teardown.sh
~~~

To delete only the control agent setup by leave the K8s cluster in place, run the following commands:

1. cd to subfolder for desired k8s provider
2. Run the following command:
~~~
SCH_ORG=<org> SCH_USER=<user>@<org> SCH_PASSWORD=<password> KUBE_CLUSTER_NAME=<your_cluster_name> ./teardown-services.sh
~~~



## Environment Variables
The following properties are common to all versions of this script.  

*See the individual K8s Provider folders for additional environment variable information.*


### Required

SCH_ORG - SCH Org you wish to connect to K8s.

SCH_USER - SCH User Id within Org with admin rights.  Format should be <user>@<org>

SCH_PASSWORD - SCH Password


### Optional

SCH_URL - URL of SCH instance.  Default is "https://cloud.streamsets.com"

KUBE_NAMESPACE - namespace to be created/used in K8s.  Default "streamsets"

KUBE_CREATE_CLUSTER - Should a new K8s instance be created (Startup only)
  - Set (any value) = true
  - Not set (default) = false

KUBE_DELETE_CLUSTER - Should a new K8s instance be deleted (Teardown only)
  - Set (any value) = true
  - Not set (default) = false

KUBE_CLUSTER_NAME - Name of cluster to be created/used as seen in the EKS web UI
  - Default is "streamsets-quickstart"

KUBE_NODE_INITIALCOUNT - The number of nodes the cluster should be created with.  Default is 3.

KUBE_PROVIDER_GEO = The cloud-rpovider specific location or datacenter where the cluster is to be created.
  - Value will be cloud provider specific.  
  - See README for specific cloud provider for default value.

KUBE_PROVIDER_MACHINETYPE = Type of machine to be used for nodes when the cluster is created.  
  - Value will be cloud provider specific.  
  - See README for specific cloud provider for default value.

SDC_DOCKER_IMAGE - The Name of the Docker iamge to be used.
  - Default is "streamsets/datacollector"
SDC_DOCKER_TAG - The version of SDC to be deployed
  - Default is "latest"
  - If you want an older version, refer to Dockerhub to see the full list of allowed values.


SCH_AGENT_NAME - SCH User Id within Org with admin rights.  Format should be <user>@<org>
  - Default is ${KUBE_CLUSTER_NAME}-schagent
SCH_DEPLOYMENT_NAME - SCH Org you wish to connect to K8s.
  - Default - ${SCH_AGENT_NAME}-deployment-01
SCH_DEPLOYMENT_LABELS - Command delimted list of lables to be applied to provisioned Data Collector instances.
  - Default - all,${KUBE_CLUSTER_NAME},${SCH_AGENT_NAME},${SCH_DEPLOYMENT_NAME},${SDC_DOCKER_TAG}
SCH_DEPLOYMENT_TYPE - Use case for SDC instances.  Defines how SDC instances will be used and how the UI will be be exposed.
  - AUTHORING - (Default) A single SDC instance with access to the UI via a Public URL.  Includes an Ingress server and loadBalancer.
  - EXECUTION - A group of SDC instancs that can be scaled via the SCH Deployments screen.  UI access with K8s port forwarding only.
  - AUTOSCALE - (under development) Same EXECUTON except scaling happens automatically in response to cpu load


DOCKER_USER - User ID for your Docker Hub account
  - Only required if you will be using a customer Docker image stored in a private repository
DOCKER_PASSWORD - Password for your Docker Hub account
  - Only required if you will be using a customer Docker image stored in a private repository
DOCKER_EMAIL - Email associated with your Docker Hub account
  - Only required if you will be using a customer Docker image stored in a private repository
