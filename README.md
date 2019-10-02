# control-agent-quickstart

This project provides pre-built scripts to configure Streamsets Control Hub (SCH) to work with various Kubernetes (K8s) providers.  You may use an existing K8s cluster or have the scripts generate a new one.


## Known Limitations

- The agent and deployment configurations produced by this script are intended for demonstration purposes.  They are not routinely tested against production environment conditions.
- Kerberos principal and keytab configuration in not currently supported by these scripts


## Deployment Modes

This script can create deployments for the the following use cases:

#### 1. AUTHORING (Default)
A single SDC instance with access to the UI via a Public URL.  This configuration includes an ingress server and loadBalancer deployment within K8s.

The details of the loadBalancer implementation will vary depending on the K8s provider you use.  If you are working on a private K8s installation that does not implement a loadBalancer you will not be able to access the UI without modifying this script.

The ingress deployment used Traefik and provides SSL termination. The SSL configuration uses a self-signed certificate.   **Before you can use the SDC instance for pipeline validations and previews from SCH, you must click on the Datacollector's link within SCH and accept the self-signed certificate.**

#### 2. EXECUTION
A group of SDC instancs that can be scaled via the SCH Deployments screen.  

These instances are not intended for development or any other activities that require routine access to the SDC UI.  The links displayed on SCH Data Collectors screeen do not work.  They are only intended to document that naem of the pod within the K8s instance.  **Remote access to the SDC UI is possible, but only with K8s port forwarding only.**

To access the UI for an SDC instance you need to:
1. Find the name of the instance you want to access via SCH Data Collectors screen or `kubectl get pods` command.
2. Enter port forwarding command via kubectl.  Example:
> `kubectl port-forward pods/${Instance-Name} 18777:18630
Forwarding from 127.0.0.1:18777 -> 18630
Forwarding from [::1]:18777 -> 18630`

  Where `Instance-Name` is the value from step 1.

3. Open your browser to `localhost:18777`


#### 3. AUTOSCALE
Same as EXECUTON mode except the number of SDC instances will be scaled automatically in response to to cpu load.

Scaling is implemented via the K8s HorizontalPodAutoscaler.  This requires a Metric Server deployment in K8s cluster.  The Metric Server is included by default in K8s deployments of cloud providers.  If you are adapting this
script for use with custom K8s cluster, you may need to take extra steps to add this service. See K8s the documentation for more details.

NOTE: Autocaling is based on the host load as seen by K8s.  This is different than the values displayed in SCH which are based on the JVM load.


## Kubernetes Cluster Provider Variations

CAQ provides a generic implementation to work with any Kubernetes environment as well several variations for the major major cloud providers.  Vendor-specific variations include the ability to dynamically create and configure the Kubernetes Cluster itself at start time.

The included variations are:

| Sub-directory | Used for...    |
| --- | --- |
| k8s-eks | Amazon Elastic Kubernetest Serivec (EKS) |
| k8s-aks  | Azure Kubernetes Services (AKS) |
| k8s-gcp |  Google Kubernetes Engine (GKE)
| k8s-generic | Any K8S compliant environemtn |

Please refer to the Readme in each provider's corresponding sub-directory for provider-specific options and details.

## Firewall Management Framework

If you are using a private SCH instance and there is a firewall separating that SCH instances from your Kubernetes instance, then you will need to open that firewall to incoming traffic from th ip addresses of your K8s nodes.  In cases where this script is used to create the K8s cluster, the IPs would not be available in advance and therefore need to opened up as part of this scripts execution.  For this reason, CAQ includes a framework to open a firewall to Node IP addresses when a K8s is created and to close the firewall to those same addresses when the K8s cluster is destroyed.

The user must implement a firewall management script for the type of firewall they will be using and place that script in the common sub-directory. The common sub-directory contains an example for managing GCP firewall rules.  The name of then scripts must then be exported via the variable SCH_FWRULE_UTIL.  For example:

  export SCH_FWRULE_UTIL=my-firewall-manager.sh   

In general these scripts must support the following usage:
~~~
$ ./my-firewall-manager.shkube [ACTION] [IP]
  - ACTION:
      add               Create K8s cluster and create configuration in SCH
      remove            Create configuration in SCH

  - IP: Comma delimted list of IP addresses to be processed
~~~

## Prerequisites:

1. kubectl (or compactible utiliy like Openshift's oc)
2. jq
3. envsubst
  - Not included by default on MacOS
4. k8s metrics server (AUTOSCALE deployments only)


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

KUBE_CREATE_CLUSTER - Should a new K8s instance be created (Startup only)
  - Set (any value) = true
  - Not set (default) = false

KUBE_DELETE_CLUSTER - Should a new K8s instance be deleted (Teardown only)
  - Set (any value) = true
  - Not set (default) = false

KUBE_CLUSTER_NAME - Name of cluster to be created/used as seen in the EKS web UI
  - Default is "streamsets-quickstart"

KUBE_CONTEXT_NAME - Name of the context to be created in Kubectl's Config file
  - Default is KUBE_CLUSTER_NAME
  - A value of "?" indicates the script should use the existing cluster defined by your current kubectl context.

  KUBE_NAMESPACE - namespace to be created/used in K8s.  
    - Default is "streamsets"
    - A value of "?" indicates the script should use the existing namespace associated with your kubectl context.
      - KUBE_CONTEXT_NAME must also be set to "?" to use this option.
      - To declare the default namespace for a given kubectl context, use command similar to:

        > kubectl config set-context *my-context-name* --namespace=*my-namespace*

        For more information on creating namespaces and configuring kubectl, please refer to the documentation from your Kubernetes provider.

KUBE_NODE_INITIALCOUNT - The number of nodes the cluster should be created with.  
  - Default is 1 if SCH_DEPLOYMENT_TYPE is set to "AUTHORING".  Otherwise the default is 3.

KUBE_PROVIDER_GEO = The cloud-rpovider specific location or datacenter where the cluster is to be created.
  - Value will be cloud provider specific.  
  - See README for specific cloud provider for default value.

KUBE_PROVIDER_MACHINETYPE = Type of machine to be used for nodes when the cluster is created.  
  - Value will be cloud provider specific.  
  - See README for specific cloud provider for default value.

KUBE_EXEC - The name of the Kubernetes management cli utility to be used.
  - Default kubectl

SDC_DOCKER_IMAGE - The Name of the Docker iamge to be used.
  - Default is "streamsets/datacollector"

SDC_DOCKER_TAG - The version of SDC to be deployed
  - Default is "latest"
  - If you want an older version, refer to Dockerhub to see the full list of allowed values.

SDC_CPUS - Minimum number of CPUs to allocate for each replica (AUTOSCALE deployments only)
  - Default = 2
  - WARNING: If no node contains the requested number of CPUs, K8s will place the POD in a PENDING status.

SDC_REPLICAS - Number of replicas to instantiate at in start up.
  - Default = 1
  - WARNING: This variable is ignored by AUTHORING deployments which always create 1 and only 1 replica.

SDC_REPLICAS_MIN - Maximum number of SDC instances to execute (AUTOSCALE deployments only)
  - Default = 1

SDC_REPLICAS_MAX - Minimum number of SDC instances to execute (AUTOSCALE deployments only)
  - Default = 10

SDC_REPLICAS_CPU_THRESHOLD - CPU usage level at which new SDC instances will be spawned (AUTOSCALE deployments only)
  - Default is 50
  - Value represents a percentage of the CPU count defined in SDC_REPLICAS_CPUS


SCH_AGENT_DOCKER_TAG - The version of the Streamsets Control Agent
  - Default is "latest"
  - If you want an older version, refer to Dockerhub to see the full list of allowed values.

SCH_AGENT_NAME - SCH User Id within Org with admin rights.  Format should be <user>@<org>
  - Default is ${KUBE_CLUSTER_NAME}-pa


SCH_DEPLOYMENT_NAME - SCH Org you wish to connect to K8s.
  - Default - ${SCH_AGENT_NAME}-deployment-01

SCH_DEPLOYMENT_LABELS - Command delimted list of lables to be applied to provisioned Data Collector instances.
  - Default - all,${KUBE_CLUSTER_NAME},${SCH_AGENT_NAME},${SCH_DEPLOYMENT_NAME},${SDC_DOCKER_TAG}

SCH_DEPLOYMENT_TYPE - Defines how SDC instances will be used and how the UI will be be exposed.
  - See <a href="#heading-ids">Deployment Modes</a> for more details

INGRESS_PORT_HTTPS - The port on public loadbalancer for accessing the SDC instance via HTTPS.
  - Default - 80
  - The HTTP endpoint will redirect all calls to the HTTPS endpoint.

INGRESS_PORT_HTTPS - The port on public loadbalancer for accessing the SDC instance via HTTPS.
  - Default - 443

DOCKER_USER - User ID for your Docker Hub account
  - Only required if you will be using a customer Docker image stored in a private repository

DOCKER_PASSWORD - Password for your Docker Hub account
  - Only required if you will be using a customer Docker image stored in a private repository

DOCKER_EMAIL - Email associated with your Docker Hub account
  - Only required if you will be using a customer Docker image stored in a private repository
