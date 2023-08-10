# Starting Minikube
In order to give enough resources to Minikube start it with next command to give it 4 cpus and 8GB of RAM memory:

`minikube start --memory 8192 --cpus 4`

# Sample Command
Running next command being at folder `./control-agent-quickstart/k8s-minikube` will register a provisioning agent against cloud SCH Streamsets instance:

`SCH_URL=https://cloud.streamsets.com SCH_ORG="sch-bcn" SCH_USER="admin@sch-bcn" SCH_PASSWORD="*****HIDDEN*****" KUBE_CREATE_CLUSTER=1 KUBE_CLUSTER_NAME=minikube ./startup.sh`