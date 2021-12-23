<!-- https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-config/ -->
# kubeadm config

```bash

kubeadm init

kubeadm join

kubeadm reset

kubeadm upgrade

# print the default configuration
kubeadm config print

# This command prints objects such as the default init configuration that is used for 'kubeadm init'.  Options inherited from parent commands: --kubeconfig string     Default: "/etc/kubernetes/admin.conf"
kubeadm config print init-defaults [ flags | -h, --help ]

# This command prints objects such as the default join configuration that is used for 'kubeadm join'.  Options inherited from parent commands: --kubeconfig string     Default: "/etc/kubernetes/admin.conf"
kubeadm config print join-defaults [ flags | --component-configs strings | -h, --help ] 


# This command lets you convert configuration objects of older versions to the latest supported version, locally in the CLI tool without ever touching anything in the cluster. In this version of kubeadm, the following API versions are supported:
# kubeadm.k8s.io/v1beta3
#--new-config string
#Path to the resulting equivalent kubeadm config file using the new API version. Optional, if not specified output will be sent to STDOUT.
#--old-config string
#Path to the kubeadm config file that is using an old API version and should be converted. This flag is mandatory.
# Options inherited from parent commands
# --kubeconfig string     Default: "/etc/kubernetes/admin.conf"
# The kubeconfig file to use when talking to the cluster. If the flag is not set, a set of standard locations can be searched for an existing kubeconfig file.
# --rootfs string
#[EXPERIMENTAL] The path to the 'real' host root filesystem.
kubeadm config migrate [flags | --new-config string | --old-config string | -h, --help]

# Print a list of images kubeadm will use. The configuration file is used in case any images or image repositories are customized
# Options
# --allow-missing-template-keys     Default: true
# If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to golang and jsonpath output formats.
# --config string
#Path to a kubeadm configuration file.
# -o, --experimental-output string     Default: "text"
# Output format. One of: text|json|yaml|go-template|go-template-file|template|templatefile|jsonpath|jsonpath-as-json|jsonpath-file.
# --feature-gates string
# A set of key=value pairs that describe feature gates for various features. Options are:
# IPv6DualStack=true|false (BETA - default=true)
#PublicKeysECDSA=true|false (ALPHA - default=false)
# RootlessControlPlane=true|false (ALPHA - default=false)
# --image-repository string     Default: "k8s.gcr.io"
# Choose a container registry to pull control plane images from
# --kubernetes-version string     Default: "stable-1"
# Choose a specific Kubernetes version for the control plane.
# --show-managed-fields
# If true, keep the managedFields when printing objects in JSON or YAML format.
kubeadm config images list [ flags | -h, --help  ]


# Pull images used by kubeadm
# Options
# --config string
# Path to a kubeadm configuration file.
# --cri-socket string
# Path to the CRI socket to connect. If empty kubeadm will try to auto-detect this value; use this option only if you have more than one CRI installed or if you have non-standard CRI socket.
# --feature-gates string
# A set of key=value pairs that describe feature gates for various features. Options are:
# IPv6DualStack=true|false (BETA - default=true)
# PublicKeysECDSA=true|false (ALPHA - default=false)
# RootlessControlPlane=true|false (ALPHA - default=false)
# --image-repository string     Default: "k8s.gcr.io"
# Choose a container registry to pull control plane images from
# --kubernetes-version string     Default: "stable-1"
# Choose a specific Kubernetes version for the control plane.
# Options inherited from parent commands
# --kubeconfig string     Default: "/etc/kubernetes/admin.conf"
# The kubeconfig file to use when talking to the cluster. If the flag is not set, a set of standard locations can be searched for an existing kubeconfig file.
# --rootfs string
# [EXPERIMENTAL] The path to the 'real' host root filesystem.
kubeadm config images pull [flags]


# Uploading control-plane certificates to the cluster
# By adding the flag --upload-certs to kubeadm init you can temporary upload the control-plane certificates to a Secret in the cluster. Please note that this Secret will expire automatically after 2 hours. The certificates are encrypted using a 32byte key that can be specified using --certificate-key. The same key can be used to download the certificates when additional control-plane nodes are joining, by passing --control-plane and --certificate-key to kubeadm join.
# The following phase command can be used to re-upload the certificates after expiration.  
# Setting the node name 
# By default, kubeadm assigns a node name based on a machine's host address. You can override this setting with the --node-name flag. The flag passes the appropriate --hostname-override value to the kubelet.

kubeadm init phase upload-certs --upload-certs --certificate-key=SOME_VALUE --config=SOME_YAML_FILE

# If the flag --certificate-key is not passed to kubeadm init and kubeadm init phase upload-certs a new key will be generated automatically.

# The following command can be used to generate a new key on demand:

kubeadm certs certificate-key

# Setting the node name 
# By default, kubeadm assigns a node name based on a machine's host address. You can override this setting with the --node-name flag. The flag passes the appropriate --hostname-override value to the kubelet.
```


