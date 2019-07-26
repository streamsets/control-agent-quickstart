
This example uses AWS EKS as the Kubernetes provider.

## AWS Region and AvailabilityZones

In addition to selecting a region that supports EKS, you may also need to consider the avaialability of host resources within the AvailabilityZones of the that Region.

By default, this script leverage a default AWS-supplied Cloudformation template for the EKS VPCs.  This template is hard-coded to use the first three availablity zones: "a" "b" and "c".  If for some reason one of these zones is unavailable or has insufficient capacity, this script will fail.  (***Warning*** - Popular regions such as the us-east-1 Region will often have problems with limited availablity).

When the a, b and c AvailabilityZones are not all available or lack sufficient resources, you have two options:
  1. Select a different Region
  2. Use a custom Cloudformation templates

To implement option 2, you may copy the AWS-supplied template to a local file and then alter the pointers found under Resources / Subnet## / Properties AvailabilityZone.  As an example, file amazon-eks-vpc-sample-acd.yaml has been altered to use to the a, c and d AvailabilityZones (Warning - he us-east-1 ) an example that uses t

Refer to the details of the EKS_VPC_TEMPLATE environment variable below for the location of the default template and how to configure script to use a local file.



The The us-east-1 is of course popular region, but it also can have chonic availa popular region
 The second option is supported by
The us-east



## Prerequisites

*[See project root READ.md file for additional prerequisites]*

1. EKS Service IAM Role
  - See https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html
2. aws cli
3. aws-iam-authenticator
  - See https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html
4. SCH 3.10 or higher

## Usage

1. Create and source an environment script that sets all the desired environment values.

  See the Environment Variables section below for all of the possible environment variables. See the file sample-env.sh for a minimal example of a user-defined environment script.

2. Run the one of the action scripts below.

  > TIP: Create a resuable environment script is recommnded.  But if you wish to bypass this step you can combine both of the above steps into a single command using a form which looks something like:
  >  ~~~
  >  SCH_ORG=<org> SCH_USER=<user>@<org> SCH_PASSWORD=<password> KUBE_NAMESPACE="streamsets" CREATE_GKE_CLUSTER=1 GKE_CLUSTER_NAME=<your_cluster_name> ./startup.sh
  >  ~~~

## Action Scripts

#### startup.sh

  - Starts a EKS Cluster, EC2 worker nodes, SCH Provisioning agent and SCH Deployment   

  Example:
  ~~~
  ./startup.sh
  ~~~

#### startup-agent.sh <suffix>
  - Uses an existing EKS cluster and worker nodes.  Starts SCH Provisioning agent and SCH Deployment.  

  The name of the existing cluster is defined by the environment variable ${KUBE_CLUSTER_NAME} (see below for more details).

  The <suffix> parameter defines a unique string to be appended to the end of the agent name.

  Example:
    ~~~
    ./startup-agent.sh 02
    ~~~

   Note: The agent that is by deafule created with the original cluster using the startup.sh scipt is "01"

#### teardown.sh

   - Deletes an EKS Cluster, and any EC2 worker nodes, SCH Provisioning agent and SCH Deployment defined on that cluster   

   Example:
   ~~~
   ./teardown.sh
   ~~~

#### teardown-agent.sh <suffix>
  - Deletes an SCH Provisioning agent and any dependent SCDeployments.  

  The name of the existing cluster is defined by thenvironment variable ${KUBE_CLUSTER_NAME} (see below fomore details).

  The <suffix> parameter defines a unique string to bappended to the end of the agent name.

  Example:
   ~~~
   ./teardown-agent.sh 02
   ~~~

  > Note: The agent that is created by default with the original clusteusing the startup.sh scipt is "01"

## Enviroment Variables:

*[See project root READ.md file for additional environment variables]*


### Required

AWS_KEYPAIR_NAME - An AWS Keypair that is used to start and access the EKS Nodes on EC2.
> *Warning* - If you wan to access one of the host via SSH, you will need to add SSH to the generated security group used by the EC2 hosts.

AWS_REGION - AWS Region to be used.
- The script will throw an error if there is insufficient capacity in the selected Region.

EKS_IAM_ROLE - ARN of IAM Role authorised to manage EKS instances


### Optional

KUBE_CREATE_CLUSTER - Should a new K8s instance be created (Startup only)
  - Set (any value) = true
  - Not set (default) = false
KUBE_DELETE_CLUSTER - Should a new K8s instance be deleted (Teardown only)
  - Set (any value) = true
  - Not set (default) = false
KUBE_CLUSTER_NAME - Name of cluster to be created/used as seen in the EKS web UI
  - Default is "streamsets-quickstart"


EKS_VPC_TEMPLATE - Cloudformation template to create AWS VPC.
  - Default is "https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-02-11/amazon-eks-vpc-sample.yaml"}
  - Also supports templates in local file.
    - Example:
      `EKS_VPC_TEMPLATE=file:///home/user/myvpctemplate.yaml`

EKS_NODE_GRP_TEMPLATE - Cloudformation template to create K8S Nodes.
  - Default is "https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-02-11/amazon-eks-nodegroup.yaml"}
EKS_NODE_IMAGEID - The AMI to be used for K8s
  - Default is "ami-081099ec932b99961"  #amazon-eks-node-1.11-v20190211
  - *Warning* - Some versions of the AWS provided AMI for EKS have a bug that results in insufficient file handles for SDC.  See https://github.com/awslabs/amazon-eks-ami/issues/233 for more information.
EKS_NODE_INSTANCETYPE - AWS Instance type to be use for K8S Nodes
  - Default is "t3.small"
EKS_NODE_GROUP_NAME - User defined name for EKS node group
EKS_NODE_INITIALCOUNT - Number of worker nodes to create when cluster is started
  - Default is "3"

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
  - Default - all,${KUBE_CLUSTER_NAME},${SCH_AGENT_NAME},${SCH_DEPLOYMENT_NAME},${SDC_DOCKERTAG}


DOCKER_USER - User ID for your Docker Hub account
  - Only required if you will be using a customer Docker image stored in a private repository
DOCKER_PASSWORD - Password for your Docker Hub account
  - Only required if you will be using a customer Docker image stored in a private repository
DOCKER_EMAIL - Email associated with your Docker Hub account
  - Only required if you will be using a customer Docker image stored in a private repository
