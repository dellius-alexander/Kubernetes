#!/usr/bin/env bash
###############################################################################
# kube_binary
KUBEADM=$(command -v kubeadm)
###############################################################################
__teardown__(){
###############################################################################
# get_env $(find -type f -name 'k8s.env')

    # Verify kubeadm and kubectl binary

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
}
###############################################################################
get_env $(find -type f -name 'k8s.env')
__teardown__
# kubeadm init phase certs all \
#     --add-dir-header=true \
#     --cert-dir=${PWD}/cert_manager/cert/ 
CERT_MANAGER=$(find -type d -name 'cert_manager')

    # Initialize Kubernetes Cluster
    ${KUBEADM} init \
        # # # # private key file
        --proxy-client-key-file \
        # # # # signed client certificate file
        --proxy-client-cert-file \
        # # # # certificate of the CA that signed the client certificate file
        --requestheader-client-ca-file \
        # valid Common Name values (CNs) in the signed client certificate
        --requestheader-allowed-names="" \
        # apiserver advertise address
        --apiserver-advertise-address=${__APISERVER_ADVERTISE_ADDRESS__} \
        # pod network cidr
        --pod-network-cidr=${__POD_NETWORK_CIDR__}

        # cp /etc/kubernetes/pki/ ./cert_manager/cert/ -r && \
exit 0

# Run this command in order to set up the Kubernetes control plane

# The "init" command executes the following phases:
# ```
# preflight                    Run pre-flight checks
# certs                        Certificate generation
#   /ca                          Generate the self-signed Kubernetes CA to provision identities for other Kubernetes components
#   /apiserver                   Generate the certificate for serving the Kubernetes API
#   /apiserver-kubelet-client    Generate the certificate for the API server to connect to kubelet
#   /front-proxy-ca              Generate the self-signed CA to provision identities for front proxy
#   /front-proxy-client          Generate the certificate for the front proxy client
#   /etcd-ca                     Generate the self-signed CA to provision identities for etcd
#   /etcd-server                 Generate the certificate for serving etcd
#   /etcd-peer                   Generate the certificate for etcd nodes to communicate with each other
#   /etcd-healthcheck-client     Generate the certificate for liveness probes to healthcheck etcd
#   /apiserver-etcd-client       Generate the certificate the apiserver uses to access etcd
#   /sa                          Generate a private key for signing service account tokens along with its public key
# kubeconfig                   Generate all kubeconfig files necessary to establish the control plane and the admin kubeconfig file
#   /admin                       Generate a kubeconfig file for the admin to use and for kubeadm itself
#   /kubelet                     Generate a kubeconfig file for the kubelet to use *only* for cluster bootstrapping purposes
#   /controller-manager          Generate a kubeconfig file for the controller manager to use
#   /scheduler                   Generate a kubeconfig file for the scheduler to use
# kubelet-start                Write kubelet settings and (re)start the kubelet
# control-plane                Generate all static Pod manifest files necessary to establish the control plane
#   /apiserver                   Generates the kube-apiserver static Pod manifest
#   /controller-manager          Generates the kube-controller-manager static Pod manifest
#   /scheduler                   Generates the kube-scheduler static Pod manifest
# etcd                         Generate static Pod manifest file for local etcd
#   /local                       Generate the static Pod manifest file for a local, single-node local etcd instance
# upload-config                Upload the kubeadm and kubelet configuration to a ConfigMap
#   /kubeadm                     Upload the kubeadm ClusterConfiguration to a ConfigMap
#   /kubelet                     Upload the kubelet component config to a ConfigMap
# upload-certs                 Upload certificates to kubeadm-certs
# mark-control-plane           Mark a node as a control-plane
# bootstrap-token              Generates bootstrap tokens used to join a node to a cluster
# kubelet-finalize             Updates settings relevant to the kubelet after TLS bootstrap
#   /experimental-cert-rotation  Enable kubelet client certificate rotation
# addon                        Install required addons for passing conformance tests
#   /coredns                     Install the CoreDNS addon to a Kubernetes cluster
#   /kube-proxy                  Install the kube-proxy addon to a Kubernetes cluster
# ```

# Usage:
#   kubeadm init [flags]
#   kubeadm init [command]

# Available Commands:
#   phase       Use this command to invoke single phase of the init workflow

    # Use this command to invoke single phase of the init workflow

    # Usage:
    #   kubeadm init phase [command]

    # Available Commands:
    #   addon              Install required addons for passing conformance tests
    #   bootstrap-token    Generates bootstrap tokens used to join a node to a cluster
    #   certs              Certificate generation
    #   control-plane      Generate all static Pod manifest files necessary to establish the control plane
    #   etcd               Generate static Pod manifest file for local etcd
    #   kubeconfig         Generate all kubeconfig files necessary to establish the control plane and the admin kubeconfig file
    #   kubelet-finalize   Updates settings relevant to the kubelet after TLS bootstrap
    #   kubelet-start      Write kubelet settings and (re)start the kubelet
    #   mark-control-plane Mark a node as a control-plane
    #   preflight          Run pre-flight checks
    #   upload-certs       Upload certificates to kubeadm-certs
    #   upload-config      Upload the kubeadm and kubelet configuration to a ConfigMap

    # Flags:
    #   -h, --help   help for phase

    # Global Flags:
    #       --add-dir-header           If true, adds the file directory to the header of the log messages
    #       --log-file string          If non-empty, use this log file
    #       --log-file-max-size uint   Defines the maximum size a log file can grow to. Unit is megabytes. If the value is 0, the maximum file size is unlimited. (default 1800)
    #       --one-output               If true, only write logs to their native severity level (vs also writing to each lower severity level)
    #       --rootfs string            [EXPERIMENTAL] The path to the 'real' host root filesystem.
    #       --skip-headers             If true, avoid header prefixes in the log messages
    #       --skip-log-headers         If true, avoid headers when opening log files
    #   -v, --v Level                  number for the log level verbosity

    # Use "kubeadm init phase [command] --help" for more information about a command.

# Flags:
#       --apiserver-advertise-address string   The IP address the API Server will advertise it's listening on. If not set the default network interface will be used.
#       --apiserver-bind-port int32            Port for the API Server to bind to. (default 6443)
#       --apiserver-cert-extra-sans strings    Optional extra Subject Alternative Names (SANs) to use for the API Server serving certificate. Can be both IP addresses and DNS names.
#       --cert-dir string                      The path where to save and store the certificates. (default "/etc/kubernetes/pki")
#       --certificate-key string               Key used to encrypt the control-plane certificates in the kubeadm-certs Secret.
#       --config string                        Path to a kubeadm configuration file.
#       --control-plane-endpoint string        Specify a stable IP address or DNS name for the control plane.
#       --cri-socket string                    Path to the CRI socket to connect. If empty kubeadm will try to auto-detect this value; use this option only if you have more than one CRI installed or if you have non-standard CRI socket.
#       --dry-run                              Don't apply any changes; just output what would be done.
#       --feature-gates string                 A set of key=value pairs that describe feature gates for various features. Options are:
#                                              IPv6DualStack=true|false (BETA - default=true)
#                                              PublicKeysECDSA=true|false (ALPHA - default=false)
#                                              RootlessControlPlane=true|false (ALPHA - default=false)
#   -h, --help                                 help for init
#       --ignore-preflight-errors strings      A list of checks whose errors will be shown as warnings. Example: 'IsPrivilegedUser,Swap'. Value 'all' ignores errors from all checks.
#       --image-repository string              Choose a container registry to pull control plane images from (default "k8s.gcr.io")
#       --kubernetes-version string            Choose a specific Kubernetes version for the control plane. (default "stable-1")
#       --node-name string                     Specify the node name.
#       --patches string                       Path to a directory that contains files named "target[suffix][+patchtype].extension". For example, "kube-apiserver0+merge.yaml" or just "etcd.json". "target" can be one of "kube-apiserver", "kube-controller-manager", "kube-scheduler", "etcd". "patchtype" can be one of "strategic", "merge" or "json" and they match the patch formats supported by kubectl. The default "patchtype" is "strategic". "extension" must be either "json" or "yaml". "suffix" is an optional string that can be used to determine which patches are applied first alpha-numerically.
#       --pod-network-cidr string              Specify range of IP addresses for the pod network. If set, the control plane will automatically allocate CIDRs for every node.
#       --service-cidr string                  Use alternative range of IP address for service VIPs. (default "10.96.0.0/12")
#       --service-dns-domain string            Use alternative domain for services, e.g. "myorg.internal". (default "cluster.local")
#       --skip-certificate-key-print           Don't print the key used to encrypt the control-plane certificates.
#       --skip-phases strings                  List of phases to be skipped
#       --skip-token-print                     Skip printing of the default bootstrap token generated by 'kubeadm init'.
#       --token string                         The token to use for establishing bidirectional trust between nodes and control-plane nodes. The format is [a-z0-9]{6}\.[a-z0-9]{16} - e.g. abcdef.0123456789abcdef
#       --token-ttl duration                   The duration before the token is automatically deleted (e.g. 1s, 2m, 3h). If set to '0', the token will never expire (default 24h0m0s)
#       --upload-certs                         Upload control-plane certificates to the kubeadm-certs Secret.

# Global Flags:
#       --add-dir-header           If true, adds the file directory to the header of the log messages
#       --log-file string          If non-empty, use this log file
#       --log-file-max-size uint   Defines the maximum size a log file can grow to. Unit is megabytes. If the value is 0, the maximum file size is unlimited. (default 1800)
#       --one-output               If true, only write logs to their native severity level (vs also writing to each lower severity level)
#       --rootfs string            [EXPERIMENTAL] The path to the 'real' host root filesystem.
#       --skip-headers             If true, avoid header prefixes in the log messages
#       --skip-log-headers         If true, avoid headers when opening log files
#   -v, --v Level                  number for the log level verbosity

# Use "kubeadm init [command] --help" for more information about a command.