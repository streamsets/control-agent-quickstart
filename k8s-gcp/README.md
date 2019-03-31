## Prerequisites

*
1. glcoud cli tool
  - See https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html
2. aws cli
3. aws-iam-authenticator
  - See https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
4. kubectl
5. jq

## Usage:

### Startup
To launch the quick start with a fresh Kubernetes cluster, run the following command:
~~~
SCH_ORG=<org> SCH_USER=<user>@<org> SCH_PASSWORD=<password> KUBE_NAMESPACE="streamsets" CREATE_GKE_CLUSTER=1 GKE_CLUSTER_NAME=<your_cluster_name> ./startup.sh
~~~

To reuse an existing cluster for the quick start, run the following commands:
~~~
gcloud container clusters get-credentials <your_cluster> --zone <your_cluster_zone> --project <your_project>
~~~
~~~
SCH_ORG=<org> SCH_USER=<user>@<org> SCH_PASSWORD=<password> KUBE_NAMESPACE="streamsets" ./startup.sh
~~~

### Teardown

To delete the quick start with AND the Kubernetes cluster, run the following command:
~~~
SCH_ORG=<org> SCH_USER=<user>@<org> SCH_PASSWORD=<password> KUBE_NAMESPACE="streamsets" DELETE_GKE_CLUSTER=1 GKE_CLUSTER_NAME=<your_cluster_name> ./teardown.sh
~~~

To delete only the control agent setup by leave the K8s cluster in place, run the following commands:
~~~
gcloud container clusters get-credentials <your_cluster> --zone <your_cluster_zone> --project <your_project>
~~~
~~~
SCH_ORG=<org> SCH_USER=<user>@<org> SCH_PASSWORD=<password> KUBE_NAMESPACE="streamsets" ./teardown.sh
~~~


## Enviroment Variables:

### Optional

GKE_CLUSTER_NAME - Name of cluster to be created/used as seen in the GKE web UI
  - Default is "streamsets-quickstart"

CREATE_GKE_CLUSTER - Should a new K8s instance be created (Startup only)
  - 1 = true
  - 2 = false (default)

CREATE_GKE_CLUSTER - Should a new K8s instance be deleted (Teardown only)
  - 1 = true
  - 2 = false (default)
