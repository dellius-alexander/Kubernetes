#!/usr/bin/env bash
set -e
###############################################################################
## PARAMETERS: [ start | stop | reset ]
INPUT=${@}
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
    # Used by: self, Control plane
firewall-cmd --zone=public --add-port=30000-32767/tcp --permanent
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
# Create k8s ssl certificate key pair
__create_k8s_ssl()
{
#export $(cat cert_manager.env | grep -v '#' | awk '/=/ {print $1}')
# Generate a ca.key with 2048bit:
COMMON_NAMES=${@}
CERT_MANAGER=$(find -type d -name 'cert_manager')
echo "CERT-MANAGER: ${CERT_MANAGER}"
echo "Common Name(s):"  ${COMMON_NAMES}
openssl genrsa -out "${CERT_MANAGER}/cert/ca.key" 2048 && \
# According to the ca.key generate a ca.crt (use -days to set the certificate 
# effective time):
openssl req -x509 -new -nodes -key "${CERT_MANAGER}/cert/ca.key" \
    -subj "/CN=${COMMON_NAMES}" \
    -days 365 -out "${CERT_MANAGER}/cert/ca.crt" && \
# Generate a server.key with 2048bit:
openssl genrsa -out "${CERT_MANAGER}/cert/server.key" 2048 && \
# Generate the certificate signing request based on the config file:
openssl req -new -key "${CERT_MANAGER}/cert/server.key" \
    -out "${CERT_MANAGER}/cert/server.csr" \
    -config "${CERT_MANAGER}/csr.conf" && \
# Generate the server certificate using the ca.key, ca.crt and server.csr:
openssl x509 -req -in "${CERT_MANAGER}/cert/server.csr" \
    -CA "${CERT_MANAGER}/cert/ca.crt" -CAkey "${CERT_MANAGER}/cert/ca.key" \
    -CAcreateserial -out "${CERT_MANAGER}/cert/server.crt" -days 10000 \
    -extensions v3_ext -extfile "${CERT_MANAGER}/csr.conf" && \
# View the certificate:
openssl x509  -noout -text -in "${CERT_MANAGER}/cert/server.crt"
}
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
    __create_k8s_ssl "${__HOSTNAME__}" "${__APISERVER_ADVERTISE_ADDRESS__}"
    CERT_MANAGER=$(find -type d -name 'cert_manager')
    echo "CERT-MANAGER: ${CERT_MANAGER}"
    # On kmaster
    # Initialize Kubernetes Cluster     # apiserver advertise address     # pod network cidr
    ${KUBEADM} init --cert-dir=/etc/kubernetes/pki \
    --certificate-key=/etc/kubernetes/pki/ca.key \
    --control-plane-endpoint="${__MASTER_NODE__}" \
    --apiserver-bind-port="${__KUBERNETES_SERVICE_PORT__}" \
    --apiserver-advertise-address="${__APISERVER_ADVERTISE_ADDRESS__}" \
    --apiserver-cert-extra-sans="${__MASTER_NODE__}","${__APISERVER_ADVERTISE_ADDRESS__}" \
    --pod-network-cidr="${__POD_NETWORK_CIDR__}"

    wait $!

    # View the certificate:
    openssl x509  -noout -text -in "/etc/kubernetes/pki/server.crt"

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
    curl -fsSLo ./calico/calico.yaml https://docs.projectcalico.org/manifests/calico.yaml &2>/dev/null
    ${KUBECTL} --kubeconfig=${__KUBECONFIG__} create -f ./calico/calico.yaml
    wait $!
    # Copy pki files to cert_manager/cert/ and change permissions
    cp /etc/kubernetes/pki/* ./cert_manager/cert/ -r
    chown -R ${__USER__}:${__USER__} ./cert_manager
    # Metric Server
    ${KUBECTL} --kubeconfig=${__KUBECONFIG__} create configmap extension-apiserver-authentication-reader -n kube-system  \
    --from-file=apiserver.crt=/etc/kubernetes/pki/apiserver.crt \
    --from-file=apiserver.key=/etc/kubernetes/pki/apiserver.key \
    --from-file=ca.crt=/etc/kubernetes/pki/ca.crt \
    --from-file=client.crt=/etc/kubernetes/pki/apiserver-kubelet-client.crt \
    --from-file=client.key=/etc/kubernetes/pki/apiserver-kubelet-client.key \
    --from-file=kubeconfig=/home/dalexander/.kube/config -o yaml > extension-apiserver-authentication.yaml  # create configmap extension-apiserver-authentication-reader
    #
    CONFIG_MAP=$(find ~+ -type f -name 'extension-apiserver-authentication')
    #
        ${KUBECTL} --kubeconfig=${__KUBECONFIG__} taint nodes --all \
        node-role.kubernetes.io/master-
        #
    if [[ -f "${CONFIG_MAP}" ]]; then
        printf "\n\n${RED}--Deploying Metric Server Daemonset...${NC}\n\n"
        ${KUBECTL} --kubeconfig=${__KUBECONFIG__}  apply -f \
        ${CONFIG_MAP}
        ${KUBECTL} --kubeconfig=${__KUBECONFIG__}  apply -f \
        $(find ~+ -type f -name 'metrics-server.yaml')
        wait $!

    else
        # ${KUBECTL} --kubeconfig=${__KUBECONFIG__} taint nodes --all \
        #     node-role.kubernetes.io/master-
        #####################################################################
        # Standard
        # Metrics Server can be installed either directly from YAML manifest or via the 
        # official Helm chart. To install the latest Metrics Server release from the 
        # components.yaml manifest, run the following command.
        # https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
        ${KUBECTL} --kubeconfig=${__KUBECONFIG__}  apply -f \
        $(find ~+ -type f -name 'metrics-server.yaml')
        #####################################################################
        # High Availability
        # Metrics Server can be installed in high availability mode directly from a YAML 
        # manifest or via the official Helm chart by setting the replicas value greater 
        # than 1. To install the latest Metrics Server release in high availability mode 
        # from the high-availability.yaml manifest, run the following command.
            # ${KUBECTL} --kubeconfig=${__KUBECONFIG__}  apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability.yaml
    fi
    #
    # check cluster stats and all contexts
    ${KUBECTL} --kubeconfig=${__KUBECONFIG__} get all -A

    # Cluster join command
    printf "\n\n${RED}--Printing join token...${NC}\n\n"
    ${KUBEADM} token create --print-join-command
    wait $!

    # Kubeadm config 
    ${KUBECTL} --kubeconfig=${__KUBECONFIG__} get cm kubeadm-config  \
    -n kube-system -o yaml > kubeadm-config.yaml


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
__test_input__() {
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
    if [[ "${i}" =~ ^(3)$ ]]; then
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

    __test_input__
fi

}   # End of __test_input__
###############################################################################
###############################################################################
##########################################################################
# Create k8s secret from certificate key pair
__create_k8s_secret__()
{
# create a Secret containing a signing key pair in the default namespace:
kubectl create secret tls dellius-app-ca-tls \
--cert=/etc/kubernetes/pki/ca.crt \
--key=/etc/kubernetes/pki/ca.key \
--namespace=default
}
##########################################################################
# Deploy Cert Manager
__deploy_cert_manager__()
{
# https://docs.cert-manager.io/en/release-0.8/getting-started/install/kubernetes.html
#  Install the CustomResourceDefinition resources separately
kubectl apply -f ./cert_manager/00-crds.yaml && \
# Create a namespace to run cert-manager in
kubectl create namespace cert-manager && \
# Disable resource validation on the cert-manager namespace
kubectl label -n cert-manager certmanager.k8s.io/disable-validation=true && \
#kubectl label namespace default certmanager.k8s.io/disable-validation=true
# Install the CustomResourceDefinitions and cert-manager itself
kubectl apply -f ./cert_manager/cert-manager.yaml -n cert-manager 
kubectl apply -f ./cert_manager/letsencrypt.yaml -n cert-manager 
# kubectl apply -f ./cert-manager/cert-manager-crds.yaml
}
###############################################################################
# echo "${INPUT[0]}"
# exit 0
__test_input__ "${INPUT[0]}"
###############################################################################