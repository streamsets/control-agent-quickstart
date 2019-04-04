
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


## Usage

### Startup

To launch the quick start with a fresh Kubernetes cluster, run the following command:
~~~
SCH_ORG=<org> SCH_USER=<user>@<org> SCH_PASSWORD=<password> KUBE_NAMESPACE="streamsets" CREATE_GKE_CLUSTER=1 GKE_CLUSTER_NAME=<your_cluster_name> ./startup.sh
~~~

To reuse an existing cluster for the quick start, run the following commands:
~~~
SCH_ORG=<org> SCH_USER=<user>@<org> SCH_PASSWORD=<password> KUBE_NAMESPACE="streamsets" ./startup.sh
~~~

### Teardown

To delete the quick start with AND the Kubernetes cluster, run the following command:
~~~
SCH_ORG=<org> SCH_USER=<user>@<org> SCH_PASSWORD=<password> KUBE_DELETE_CLUSTER=1 KUBE_CLUSTER_NAME=<your_cluster_name> ./teardown.sh
~~~

To delete only the control agent setup by leave the K8s cluster in place, run the following commands:
~~~
SCH_ORG=<org> SCH_USER=<user>@<org> SCH_PASSWORD=<password> ./teardown.sh
~~~

## Enviroment Variables:

*[See project root READ.md file for additional environment variables]*


### Required

AWS_KEYPAIR_NAME - An AWS Keypair that is used to start and access the EKS Nodes on EC2.
- *Warning* - If you wan to access one of the host via SSH, you will need to add SSH to the generated security group used by the EC2 hosts.

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

EKS_NODE_GROUP_NAME - Name to K8s node group create by script be used.
  - Default is "${KUBE_CLUSTER_NAME}-nodegrp-1"
  - "Note" - This name is used to tag AWS Cloudformation stacks and ec2 instances.  It is not directly used in the operation or managemenent of K8s itself.


SDC_DOCKER_TAG - The version of SDC to be deployed
  - Default is "latest"
  - If you want an older version, refer to Dockerhub to see the full list of allowed values.
