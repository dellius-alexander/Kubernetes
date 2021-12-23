#!/usr/bin/env bash
set -e
###############################################################################
## PARAMETERS: [ start | stop | reset ]
INPUT=${1:-"RESET"}
###############################################################################
###############################################################################
    # Verify kubelet present on host
KUBEADM=$(command -v kubeadm)
KUBECTL=$(command -v kubectl)
RED='\033[0;31m' # Red
NC='\033[0m' # No Color CAP
###############################################################################
###############################################################################
###############################################################################
    # Require sudo to run script
if [[ $UID != 0 ]]; then
    printf "\nPlease run this script with sudo: \n";
    printf "\n${RED} sudo $0 $* ${NC}\n\n";
    exit 1
fi
###############################################################################
###############################################################################
########################    GET ENVIRONMENT FILE    ###########################
###############################################################################
get_env(){
###############################################################################
# Local .env
if [ -f $1 ]; then
    # Load Environment Variables
    export $(cat $1 | grep -v '#' | awk '/=/ {print $1}')
else
    printf "${RED}Unable to load file. Check your input and rerun again...${NC}\n"
    exit $?
fi
    # Checking if environment variables have loaded
echo "Master Node address: ${__MASTER_NODE__}"
echo "Worker node 1 address: ${__WORKER_NODE_1__}"
echo "Worker node 2 address: ${__WORKER_NODE_2__}"
echo "Kubernetes API Address: ${__APISERVER_ADVERTISE_ADDRESS__}"
echo "Kubernetes POD CIDR: ${__POD_NETWORK_CIDR__}"
echo "User Home Directory: ${__USER_HOME__}"
echo "User: ${__USER__}"
echo "Kubernetes config file PATH: ${__KUBECONFIG__}"
echo "Kubernetes Service Port: ${__KUBERNETES_SERVICE_PORT__}"
echo "Kubeconfig directory: ${__KUBECONFIG_DIRECTORY__}"
echo "Kubeconfig file path: ${__KUBECONFIG_FILEPATH__}"

return 0;
}   # End of get_env
###############################################################################
###############################################################################
#####################     CHECK ENVIRONMENT VARIABLE      #####################
###############################################################################
check_env() {
###############################################################################
        ## Check envirnoment variable
if [[ -z "$1" ]]; then
        printf "\n$2 NULL\n" 1>/dev/null 2>/dev/null
        return ""
else
        printf "\n$2 $1\n" 1>/dev/null 2>/dev/null
        echo "$1"
fi

return 0;
}   # End of check_env
###############################################################################
###############################################################################
################     VERIFY KUBEADM AND KUBECTL BINARIES     ##################
###############################################################################
kube_binary(){
    # Require sudo to run script
if [[ -z ${KUBEADM} ]]; then
    printf "\nUnable to locate ${RED}kubeadm${NC} binary. \nPlease re-run this script using the ${RED}--setup${NC} flag.\n Usage:${RED} $0 [ --reset | --setup ]${NC}\n";
    printf "\n${RED}sudo $0 $*${NC}";
    exit 1
elif [[ -z ${KUBECTL} ]]; then
        printf "\nUnable to locate ${RED}kubelet${NC} binary. \nPlease re-run this script using the ${RED}--setup${NC} flag.\n Usage:${RED} $0 [ --reset | --setup ]${NC}\n";
    printf "\n$RED}sudo $0 $*${NC}";
    exit 1
fi

return 0;
}   # End of kube_binary check
###############################################################################
###############################################################################
#########################    SETUP FIREWALL RULES    ##########################
###############################################################################
firewall_rules(){
###############################################################################
    # For more details, see: https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.txt
    # Disable Firewall
# systemctl disable firewalld && systemctl stop firewalld
    # Posts to be defined on the worker nodes
    # All       kube-apiserver host     Incoming        Often TCP 443 or 6443*
firewall-cmd --zone=public --add-port=6443/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
    # Used by: kube-apiserver, etcd
    # etcd datastore    etcd hosts      Incoming        Officially TCP 2379 but can vary
firewall-cmd --zone=public --add-port=2379-2380/tcp --permanent
    # Used by: self, Control plane
firewall-cmd --zone=public --add-port=10250/tcp --permanent
    # Used by: self
firewall-cmd --zone=public --add-port=10251/tcp --permanent
    # Used by: self
firewall-cmd --zone=public --add-port=10252/tcp --permanent
    # Calico networking (BGP)   All     Bidirectional   TCP 179
firewall-cmd --zone=public --add-port=179/tcp --permanent
    # Calico networking with IP-in-IP enabled (default) All     Bidirectional   IP-in-IP, 4
firewall-cmd --zone=public --add-port=4/tcp --permanent
    # Calico networking with VXLAN enabled      All     Bidirectional   UDP 4789
firewall-cmd --zone=public --add-port=4789/tcp --permanent
    # Calico networking with Typha enabled      Typha agent hosts       Incoming        TCP 5473 (default)
firewall-cmd --zone=public --add-port=5473/tcp --permanent
    # Reload firewall
firewall-cmd --reload
    # List ports
wait $!
printf "\n${RED}Ports assignments: ${NC}\n"
firewall-cmd --zone=public --permanent --list-ports
printf "\n\n"
sleep 3
wait $!

return 0;
}   # End of firewall_rules
###############################################################################
###############################################################################
#########################     TEARDOWN CLUSTER     ############################
###############################################################################
__teardown__(){
###############################################################################
get_env $(find -type f -name 'k8s.env')

    # Verify kubeadm and kubectl binary
kube_binary

    # Reset Master Node
${KUBEADM} reset
wait $!

    # Reset IP tables
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
wait $!

    ###########################################################################
    # Deleting contents of config directories:
    # [/etc/kubernetes/manifests /etc/kubernetes/pki] Deleting files:
    # [/etc/kubernetes/admin.conf /etc/kubernetes/kubelet.conf
    # /etc/kubernetes/bootstrap-kubelet.conf /etc/kubernetes/controller-manager.conf
    # /etc/kubernetes/scheduler.conf] Deleting contents of stateful directories:
    # [/var/lib/etcd /var/lib/kubelet /var/lib/dockershim /var/run/kubernetes
    # /var/lib/cni]
rm -rf \
/etc/kubernetes/manifests \
/etc/kubernetes/pki \
/etc/kubernetes/admin.conf \
/etc/kubernetes/kubelet.conf \
/etc/kubernetes/bootstrap-kubelet.conf \
/etc/kubernetes/controller-manager.conf \
/etc/kubernetes/scheduler.conf \
/var/lib/kubelet \
/var/lib/dockershim \
/var/run/kubernetes \
/var/lib/cni \
/etc/cni/net.d \
${__KUBECONFIG_DIRECTORY__}/config
wait $!

    # Restart the kubelet
systemctl daemon-reload &&
systemctl stop kubelet &&
systemctl enable docker &&
systemctl restart docker
wait $!

return 0;
}   # END OF TEARDOWN
###############################################################################
###############################################################################
#####################    INITIALIZE CLUSTER COMPONENTS    #####################
###############################################################################
init_cluster() {
###############################################################################
    # On kmaster
    # Initialize Kubernetes Cluster
${KUBEADM} init --apiserver-advertise-address=${__APISERVER_ADVERTISE_ADDRESS__} \
--pod-network-cidr=${__POD_NETWORK_CIDR__}
wait $!

    # Setup KUBECONFIG file:
mkdir -p ${__KUBECONFIG_DIRECTORY__}
cp -i /etc/kubernetes/admin.conf  ${__KUBECONFIG_DIRECTORY__}/config
chown ${__USER__}:${__USER__}  ${__KUBECONFIG_DIRECTORY__}/config
wait $!

    # Deploy Calico network
    # Source: https://docs.projectcalico.org/v3.14/manifests/calico.yaml
    # Modify the config map as needed:
printf "\n\n${RED}--Deploying Calico Networking...${NC}\n\n"
#${KUBECTL} --kubeconfig=${__KUBECONFIG__} create -f $(find ~+ -type f -name 'calico.yaml')
${KUBECTL} --kubeconfig=${__KUBECONFIG__} create -f https://docs.projectcalico.org/manifests/calico.yaml
wait $!

    # Metric Server
if [[ -f $(find ~+ -type f -name 'metrics-ca-config.yaml') ]]; then
     printf "\n\n${RED}--Deploying Metric Server Daemonset...${NC}\n\n"
     ${KUBECTL} --kubeconfig=${__KUBECONFIG__}  apply -f $(find ~+ -type f -name 'metrics-ca-config.yaml')
     ${KUBECTL} --kubeconfig=${__KUBECONFIG__}  apply -f $(find ~+ -type f -name 'metrics-server.yaml')
     wait $!

else
${KUBECTL} --kubeconfig=${__KUBECONFIG__} taint nodes --all node-role.kubernetes.io/master-
#####################################################################
# Standard
# Metrics Server can be installed either directly from YAML manifest or via the 
# official Helm chart. To install the latest Metrics Server release from the 
# components.yaml manifest, run the following command.
${KUBECTL} --kubeconfig=${__KUBECONFIG__}  apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
#####################################################################
# High Availability
# Metrics Server can be installed in high availability mode directly from a YAML 
# manifest or via the official Helm chart by setting the replicas value greater 
# than 1. To install the latest Metrics Server release in high availability mode 
# from the high-availability.yaml manifest, run the following command.
    # ${KUBECTL} --kubeconfig=${__KUBECONFIG__}  apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability.yaml
fi
    # Cluster join command
printf "\n\n${RED}--Printing join token...${NC}\n\n"
${KUBEADM} token create --print-join-command
wait $!

# Kubeadm config 
${KUBECTL} --kubeconfig=${__KUBECONFIG__} get cm kubeadm-config  \
-n kube-system -o yaml > kubeadm-config.yaml
# Kube root ca
${KUBECTL} --kubeconfig=${__KUBECONFIG__}  get configmaps kube-root-ca.crt \
-o yaml > kubeadm-configmap.yaml

# kubectl get configMap kubeadm-config -o yaml --namespace=kube-system > kubeadm-config.yaml 
# kubeadm config print init-defaults >> kubeadm-config.yaml 
# kubeadm config print join-defaults >> kubeadm-config.yaml 
return 0
}     # End of init_cluster
###############################################################################
###############################################################################
#####################    INITIAL SETUP OF CLUSTER NODE    #####################
###############################################################################
__setup() {
###############################################################################
get_env $(find -type f -name 'k8s.env')
###############################################################################
    # Install dependencies
yum install -y git nano net-tools firewalld nfs-utils
wait $!

    # Reset IP tables
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X

    # Pre-requisites: 
    # Update /etc/hosts file So that we can talk to each of the
    # nodes in the cluster. 
cat $(find ./config -type f -name 'hosts.conf') > /etc/hosts

    # Setup firewall rules
    # Posts to be defined on the worker nodes
    # Run firewall function:
firewall_rules

    # Disable swap
swapoff -a && sed -i '/swap/d' /etc/fstab
wait $!

    # Disable SELinux
setenforce 0
sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux
wait $!

    # Update sysctl settings for Kubernetes networking
cat >/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
wait $!


# Install docker engine
yum install -y yum-utils device-mapper-persistent-data lvm2     > /dev/null 2>&1
yum-config-manager \
--add-repo https://download.docker.com/linux/centos/docker-ce.repo  > /dev/null 2>&1
wait $!


yum install -y containerd.io \
docker-ce-${__DOCKER_VERS__} \
docker-ce-cli-${__DOCKER_VERS__} >/dev/null 2>&1
systemctl enable --now docker
wait $!

if [ ! -d "/etc/docker/" ]; then
    # Create /etc/docker
    mkdir -p /etc/docker
fi
    # Set up the Docker daemon
cat $(find ~+ -type f -name 'daemon.json') > /etc/docker/daemon.json 

    # Create docker service
mkdir -p /etc/systemd/system/docker.service.d
    # Enable & Restart Docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
wait $!

    # Kubernetes Setup Add yum repository
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF


    # Install Kubernetes components
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
wait $!

    # Enable and Start kubelet service
systemctl enable --now kubelet
systemctl start kubelet
wait $!

    # Initialize Cluster
init_cluster

exit 0
}   # END OF SETUP
###############################################################################
###############################################################################
###########################    RESET CLUSTER     ##############################
###############################################################################
reset(){
###############################################################################
    # Teardown Cluster
__teardown__

    # Initialize Cluster
init_cluster

exit 0
}   # END OF RESET
###############################################################################
###############################################################################
######################    TEST THE INPUT PARAMETERS    ########################
###############################################################################
test_input() {
###############################################################################
    ## Exit if no paramaters provided
i=0
INPUT=${1:-"RESET"}
while [[ -z "${INPUT}" ]];
do
    printf "\nInitial Usage:${RED} $0 [ setup | reset | stop ]${NC}\n";
    printf "\nEnter a task parameter => ${RED} $0 [ reset | setup | stop ]${NC} to \
setup, reset or teardown the master node: ";
    in=$(read v && echo ${v})
    sleep 1
    i=$((i++))
    echo "Attempt: ${i}"
    if [[ "${i}" == 3 ]]; then
            exit 1
    fi
done

    ## Check if command is valid
if [[ "${INPUT}" =~ ^(reset|RESET)$ ]]; then
    reset
    exit 0
elif [[ "${INPUT}" =~ ^(setup|SETUP)$ ]]; then
    __setup
    exit 0
elif [[ "${INPUT}" =~ ^(test|TEST)$ ]]; then
    get_env $(find -type f -name 'k8s.env')
    printf "\nTest was successful...\n";        
    exit 0
elif [[ "${INPUT}" =~ ^(stop|STOP)$ ]]; then
    printf "\n\n${RED}TEARING DOWN CLUSTER: ${NC}${__HOSTNAME__}\n\n"
    __teardown__
    printf "\n\n${RED}Node: ${__HOSTNAME__} restored to normal...${NC}\n\n"
    exit 0
else
    echo ""
    printf "${RED}\"${INPUT}\"${NC} is not a valid option...\n"
    printf "\nUsage: ${RED}${0} [ setup | reset | stop ]${NC}\n"
    printf "\nNote: \"$0 stop\" command will teardown the node and revert node back to original state...\n"

    if [[ "${INPUT}" == 3 ]]; then
            exit 1
    fi

    test_input
fi

}   # End of test_input
###############################################################################
###############################################################################
###############################################################################
test_input ${INPUT}
###############################################################################
