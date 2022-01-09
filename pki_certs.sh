#!/usr/bin/env bash
#####################################################################
#--------------------------------------------------------------------
CERTS=(
#   ca                          # Generate the self-signed Kubernetes CA to provision identities for other Kubernetes components
  apiserver                   # Generate the certificate for serving the Kubernetes API
  apiserver-kubelet-client    # Generate the certificate for the API server to connect to kubelet
#   front-proxy-ca              # Generate the self-signed CA to provision identities for front proxy
#   front-proxy-client          # Generate the certificate for the front proxy client
#   etcd-ca                     # Generate the self-signed CA to provision identities for etcd
#   etcd-server                 # Generate the certificate for serving etcd
#   etcd-peer                   # Generate the certificate for etcd nodes to communicate with each other
#   etcd-healthcheck-client     # Generate the certificate for liveness probes to healthcheck etcd
#   apiserver-etcd-client       # Generate the certificate the apiserver uses to access etcd
#   sa                          # Generate a private key for signing service account tokens along with its public key
)
#--------------------------------------------------------------------
CERTIFICATES_DIR="/etc/kubernetes/pki"
CERTIFICATES_CSR_DIR="/etc/kubernetes/pki/csr"
CERTIFICATES_ETCD_DIR="/etc/kubernetes/pki/etcd"
CERT_MANAGER="${PWD}/cert_manager"
#--------------------------------------------------------------------
# CERTIFICATES_DIR="${PWD}/cert_manager/pki"
# CERTIFICATES_CSR_DIR="${PWD}/cert_manager/pki/csr"
# CERTIFICATES_ETCD_DIR="${PWD}/cert_manager/pki/etcd"
# CERT_MANAGER="${PWD}/cert_manager"
#--------------------------------------------------------------------
DIRS=(
    "CERTIFICATES_DIR":"/etc/kubernetes/pki"
    "CERTIFICATES_CSR_DIR":"/etc/kubernetes/pki/csr"
    "CERTIFICATES_ETCD_DIR":"/etc/kubernetes/pki/etcd"
    "CERT_MANAGER":"${PWD}/cert_manager"
)
#--------------------------------------------------------------------
# DIRS=(
#     "CERTIFICATES_DIR":"${PWD}/cert_manager/pki"
#     "CERTIFICATES_CSR_DIR":"${PWD}/cert_manager/pki/csr"
#     "CERTIFICATES_ETCD_DIR":"${PWD}/cert_manager/pki/etcd"
#     "CERT_MANAGER":"${PWD}/cert_manager"
# )
#--------------------------------------------------------------------
# Remove pki artifacts
rm -rf "/etc/kubernetes/pki/*"
# rm -rf "${PWD}/cert_manager/pki/*"
#--------------------------------------------------------------------
# create missing directories
for dir in ${DIRS[*]}; do 
    if [[ ! -d "${dir}" ]]; then
        mkdir -p $(echo ${dir} | cut -d ':' -f2);
    fi;
    # echo ${dir} | cut -d ':' -f2 ; sleep 1; 
done;
# common names
COMMON_NAMES='k8s-master 192.168.122.63'
echo ${COMMON_NAMES}

#--------------------------------------------------------------------
# Generate base ca.crt and ca.key
openssl genrsa -out "${CERTIFICATES_DIR}/ca.key" 4096 && \
# According to the ca.key generate a ca.crt (use -days to set the certificate 
# effective time):
openssl req -x509 -new -nodes -key "${CERTIFICATES_DIR}/ca.key" \
    -subj "/CN=${COMMON_NAMES}" \
    -days 365 -out "${CERTIFICATES_DIR}/ca.crt"

# Generate base ca.crt and ca.key
openssl genrsa -out "${CERTIFICATES_ETCD_DIR}/ca.key" 4096 && \
# According to the ca.key generate a ca.crt (use -days to set the certificate 
# effective time):
openssl req -x509 -new -nodes -key "${CERTIFICATES_ETCD_DIR}/ca.key" \
    -subj "/CN=${COMMON_NAMES}" \
    -days 365 -out "${CERTIFICATES_ETCD_DIR}/ca.crt"
#--------------------------------------------------------------------
# Generate additional certs
for cert in ${CERTS[*]}; do
# echo "Creating certificate for $cert";
if [[ "${cert}" =~ ^(etcd) ]]; then
    echo "Creating certificate for $cert";
    # Generate the apiserver-kubelet-client certificate key and cert
    openssl genrsa -out "${CERTIFICATES_ETCD_DIR}/${cert}.key" 4096 && 
    # Generate the csr for apiserver-kubelet-client
    openssl req -new -key "${CERTIFICATES_ETCD_DIR}/${cert}.key" \
        -out "${CERTIFICATES_CSR_DIR}/${cert}.csr" \
        -config "${CERT_MANAGER}/csr.conf" && 
    # Sign the apiserver-kubelet-client.csr:
    openssl x509 -req -in "${CERTIFICATES_CSR_DIR}/${cert}.csr" \
        -CA "${CERTIFICATES_ETCD_DIR}/ca.crt" -CAkey "${CERTIFICATES_ETCD_DIR}/ca.key" \
        -CAcreateserial -out "${CERTIFICATES_ETCD_DIR}/${cert}.crt" -days 10000 \
        -extensions v3_ext -extfile "${CERT_MANAGER}/csr.conf" && 
    # View the certificate:
    openssl x509  -noout -text -in "${CERTIFICATES_ETCD_DIR}/${cert}.crt" 
else
    echo "Creating certificate for $cert";
    # Generate the apiserver-kubelet-client certificate key and cert
    openssl genrsa -out "${CERTIFICATES_DIR}/${cert}.key" 4096 && 
    # Generate the csr for apiserver-kubelet-client
    openssl req -new -key "${CERTIFICATES_DIR}/${cert}.key" \
        -out "${CERTIFICATES_CSR_DIR}/${cert}.csr" \
        -config "${CERT_MANAGER}/csr.conf" && 
    # Sign the apiserver-kubelet-client.csr:
    openssl x509 -req -in "${CERTIFICATES_CSR_DIR}/${cert}.csr" \
        -CA "${CERTIFICATES_DIR}/ca.crt" -CAkey "${CERTIFICATES_DIR}/ca.key" \
        -CAcreateserial -out "${CERTIFICATES_DIR}/${cert}.crt" -days 10000 \
        -extensions v3_ext -extfile "${CERT_MANAGER}/csr.conf" && 
    # View the certificate:
    openssl x509  -noout -text -in "${CERTIFICATES_DIR}/${cert}.crt" 
fi;
    sleep 1;
done;