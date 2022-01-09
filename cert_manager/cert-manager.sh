#!/usr/bin/env bash
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
###############################################################################
# Create k8s ssl certificate key pair
# https://kubernetes.io/docs/setup/best-practices/certificates/
__create_k8s_ssl()
{
#export $(cat cert-manager.env | grep -v '#' | awk '/=/ {print $1}')
# Generate a ca.key with 2048bit:
mkdir -p /etc/kubernetes/pki
COMMON_NAMES=${@}
echo "Common Name(s):"  ${COMMON_NAMES}
openssl genrsa -out /etc/kubernetes/pki/ca.key 2048 && \
# According to the ca.key generate a ca.crt (use -days to set the certificate effective time):
openssl req -x509 -new -nodes -key /etc/kubernetes/pki/ca.key -subj "/CN=${COMMON_NAMES}" \
-days 365 -out /etc/kubernetes/pki/ca.crt && \
# Generate a server.key with 2048bit:
openssl genrsa -out /etc/kubernetes/pki/server.key 2048 && \
# Generate the certificate signing request based on the config file:
openssl req -new -key /etc/kubernetes/pki/server.key -out /etc/kubernetes/pki/server.csr -config csr.conf && \
# Generate the server certificate using the ca.key, ca.crt and server.csr:
openssl x509 -req -in /etc/kubernetes/pki/server.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key \
-CAcreateserial -out /etc/kubernetes/pki/server.crt -days 10000 \
-extensions v3_ext -extfile csr.conf && \
# View the certificate:
openssl x509  -noout -text -in /etc/kubernetes/pki/server.crt
}

###############################################################################
# PARAMETERS: [ COMMON NAMES: ]
__create_k8s_ssl ${@}

if [[ ! -z "${3}" ]]; then
    __deploy_cert_manager__
fi;