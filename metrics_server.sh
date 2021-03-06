#!/usr/bin/env bash
##########################################################################
# kubectl create configmap extension-apiserver-authentication-reader -n kube-system  \
# --from-file=apiserver.crt=cert-manager/cert/apiserver.crt \
# --from-file=apiserver.key=cert-manager/cert/apiserver.key \
# --from-file=ca.crt=cert-manager/cert/ca.crt \
# --from-file=client.crt=cert-manager/cert/apiserver-kubelet-client.crt \
# --from-file=client.key=cert-manager/cert/apiserver-kubelet-client.key \
# --from-file=kubeconfig=/home/dalexander/.kube/config -o yaml > extension-apiserver-authentication.yaml
##########################################################################
kubectl create configmap extension-apiserver-authentication-reader -n kube-system  \
--from-file=apiserver.crt=/etc/kubernetes/pki/apiserver.crt \
--from-file=apiserver.key=/etc/kubernetes/pki/apiserver.key \
--from-file=ca.crt=/etc/kubernetes/pki/ca.crt \
--from-file=client.crt=/etc/kubernetes/pki/apiserver-kubelet-client.crt \
--from-file=client.key=/etc/kubernetes/pki/apiserver-kubelet-client.key \
--from-file=kubeconfig=/home/dalexander/.kube/config -o yaml > extension-apiserver-authentication.yaml
##########################################################################
#  - command:
#     - kube-apiserver
#     - --advertise-address=10.0.2.129
#     - --allow-privileged=true
#     - --authorization-mode=Node,RBAC
#     - --client-ca-file=/etc/kubernetes/pki/ca.crt
#     - --enable-admission-plugins=NodeRestriction
#     - --enable-bootstrap-token-auth=true
#     - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
#     - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
#     - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
#     - --etcd-servers=https://127.0.0.1:2379
#     - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
#     - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
#     - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
#     - --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
#     - --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
#     - --requestheader-allowed-names=front-proxy-client
#     - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
#     - --requestheader-extra-headers-prefix=X-Remote-Extra-
#     - --requestheader-group-headers=X-Remote-Group
#     - --requestheader-username-headers=X-Remote-User
#     - --secure-port=6443
#     - --service-account-issuer=https://kubernetes.default.svc.cluster.local
#     - --service-account-key-file=/etc/kubernetes/pki/sa.pub
#     - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key
#     - --service-cluster-ip-range=10.96.0.0/12
#     - --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
#     - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
# - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt

##########################################################################
# Launch metrics-server

# Usage:
#    [flags]

# Metrics server flags:

#       --kubeconfig string                                                                                                                                
#                 The path to the kubeconfig used to connect to the Kubernetes API server and the Kubelets (defaults to in-cluster config)
#       --metric-resolution duration                                                                                                                       
#                 The resolution at which metrics-server will retain metrics, must set value at least 10s. (default 1m0s)
#       --version                                                                                                                                          
#                 Show version

# Kubelet client flags:

#       --deprecated-kubelet-completely-insecure                                                                                                           
#                 DEPRECATED: Do not use any encryption, authorization, or authentication when communicating with the Kubelet. This is rarely the right
#                 option, since it leaves kubelet communication completely insecure.  If you encounter auth errors, make sure you've enabled token webhook
#                 auth on the Kubelet, and if you're in a test cluster with self-signed Kubelet certificates, consider using kubelet-insecure-tls instead.
#       --kubelet-certificate-authority string                                                                                                             
#                 Path to the CA to use to validate the Kubelet's serving certificates.
#       --kubelet-client-certificate string                                                                                                                
#                 Path to a client cert file for TLS.
#       --kubelet-client-key string                                                                                                                        
#                 Path to a client key file for TLS.
#       --kubelet-insecure-tls                                                                                                                             
#                 Do not verify CA of serving certificates presented by Kubelets.  For testing purposes only.
#       --kubelet-port int                                                                                                                                 
#                 The port to use to connect to Kubelets. (default 10250)
#       --kubelet-preferred-address-types strings                                                                                                          
#                 The priority of node address types to use when determining which address to use to connect to a particular node (default
#                 [Hostname,InternalDNS,InternalIP,ExternalDNS,ExternalIP])
#       --kubelet-use-node-status-port                                                                                                                     
#                 Use the port in the node status. Takes precedence over --kubelet-port flag.

# Apiserver secure serving flags:

#       --bind-address ip                                                                                                                                  
#                 The IP address on which to listen for the --secure-port port. The associated interface(s) must be reachable by the rest of the cluster, and
#                 by CLI/web clients. If blank or an unspecified address (0.0.0.0 or ::), all interfaces will be used. (default 0.0.0.0)
#       --cert-dir string                                                                                                                                  
#                 The directory where the TLS certs are located. If --tls-cert-file and --tls-private-key-file are provided, this flag will be ignored.
#                 (default "apiserver.local.config/certificates")
#       --http2-max-streams-per-connection int                                                                                                             
#                 The limit that the server gives to clients for the maximum number of streams in an HTTP/2 connection. Zero means to use golang's default.
#       --permit-address-sharing                                                                                                                           
#                 If true, SO_REUSEADDR will be used when binding the port. This allows binding to wildcard IPs like 0.0.0.0 and specific IPs in parallel, and
#                 it avoids waiting for the kernel to release sockets in TIME_WAIT state. [default=false]
#       --permit-port-sharing                                                                                                                              
#                 If true, SO_REUSEPORT will be used when binding the port, which allows more than one instance to bind on the same address and port.
#                 [default=false]
#       --secure-port int                                                                                                                                  
#                 The port on which to serve HTTPS with authentication and authorization. If 0, don't serve HTTPS at all. (default 443)
#       --tls-cert-file string                                                                                                                             
#                 File containing the default x509 Certificate for HTTPS. (CA cert, if any, concatenated after server cert). If HTTPS serving is enabled, and
#                 --tls-cert-file and --tls-private-key-file are not provided, a self-signed certificate and key are generated for the public address and
#                 saved to the directory specified by --cert-dir.
#       --tls-cipher-suites strings                                                                                                                        
#                 Comma-separated list of cipher suites for the server. If omitted, the default Go cipher suites will be used. 
#                 Preferred values: TLS_AES_128_GCM_SHA256, TLS_AES_256_GCM_SHA384, TLS_CHACHA20_POLY1305_SHA256, TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA,
#                 TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256, TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA, TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
#                 TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305, TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256, TLS_ECDHE_RSA_WITH_3DES_EDE_CBC_SHA,
#                 TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA, TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256, TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,
#                 TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384, TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305, TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256,
#                 TLS_RSA_WITH_3DES_EDE_CBC_SHA, TLS_RSA_WITH_AES_128_CBC_SHA, TLS_RSA_WITH_AES_128_GCM_SHA256, TLS_RSA_WITH_AES_256_CBC_SHA,
#                 TLS_RSA_WITH_AES_256_GCM_SHA384. 
#                 Insecure values: TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256, TLS_ECDHE_ECDSA_WITH_RC4_128_SHA, TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,
#                 TLS_ECDHE_RSA_WITH_RC4_128_SHA, TLS_RSA_WITH_AES_128_CBC_SHA256, TLS_RSA_WITH_RC4_128_SHA.
#       --tls-min-version string                                                                                                                           
#                 Minimum TLS version supported. Possible values: VersionTLS10, VersionTLS11, VersionTLS12, VersionTLS13
#       --tls-private-key-file string                                                                                                                      
#                 File containing the default x509 private key matching --tls-cert-file.
#       --tls-sni-cert-key namedCertKey                                                                                                                    
#                 A pair of x509 certificate and private key file paths, optionally suffixed with a list of domain patterns which are fully qualified domain
#                 names, possibly with prefixed wildcard segments. The domain patterns also allow IP addresses, but IPs should only be used if the apiserver
#                 has visibility to the IP address requested by a client. If no domain patterns are provided, the names of the certificate are extracted.
#                 Non-wildcard matches trump over wildcard matches, explicit domain patterns trump over extracted names. For multiple key/certificate pairs,
#                 use the --tls-sni-cert-key multiple times. Examples: "example.crt,example.key" or "foo.crt,foo.key:*.foo.com,foo.com". (default [])

# Apiserver authentication flags:

#       --authentication-kubeconfig string                                                                                                                 
#                 kubeconfig file pointing at the 'core' kubernetes server with enough rights to create tokenreviews.authentication.k8s.io.
#       --authentication-skip-lookup                                                                                                                       
#                 If false, the authentication-kubeconfig will be used to lookup missing authentication configuration from the cluster.
#       --authentication-token-webhook-cache-ttl duration                                                                                                  
#                 The duration to cache responses from the webhook token authenticator. (default 10s)
#       --authentication-tolerate-lookup-failure                                                                                                           
#                 If true, failures to look up missing authentication configuration from the cluster are not considered fatal. Note that this can result in
#                 authentication that treats all requests as anonymous.
#       --client-ca-file string                                                                                                                            
#                 If set, any request presenting a client certificate signed by one of the authorities in the client-ca-file is authenticated with an identity
#                 corresponding to the CommonName of the client certificate.
#       --requestheader-allowed-names strings                                                                                                              
#                 List of client certificate common names to allow to provide usernames in headers specified by --requestheader-username-headers. If empty,
#                 any client certificate validated by the authorities in --requestheader-client-ca-file is allowed.
#       --requestheader-client-ca-file string                                                                                                              
#                 Root certificate bundle to use to verify client certificates on incoming requests before trusting usernames in headers specified by
#                 --requestheader-username-headers. WARNING: generally do not depend on authorization being already done for incoming requests.
#       --requestheader-extra-headers-prefix strings                                                                                                       
#                 List of request header prefixes to inspect. X-Remote-Extra- is suggested. (default [x-remote-extra-])
#       --requestheader-group-headers strings                                                                                                              
#                 List of request headers to inspect for groups. X-Remote-Group is suggested. (default [x-remote-group])
#       --requestheader-username-headers strings                                                                                                           
#                 List of request headers to inspect for usernames. X-Remote-User is common. (default [x-remote-user])

# Apiserver authorization flags:

#       --authorization-always-allow-paths strings                                                                                                         
#                 A list of HTTP paths to skip during authorization, i.e. these are authorized without contacting the 'core' kubernetes server. (default
#                 [/healthz,/readyz,/livez])
#       --authorization-kubeconfig string                                                                                                                  
#                 kubeconfig file pointing at the 'core' kubernetes server with enough rights to create subjectaccessreviews.authorization.k8s.io.
#       --authorization-webhook-cache-authorized-ttl duration                                                                                              
#                 The duration to cache 'authorized' responses from the webhook authorizer. (default 10s)
#       --authorization-webhook-cache-unauthorized-ttl duration                                                                                            
#                 The duration to cache 'unauthorized' responses from the webhook authorizer. (default 10s)

# Features flags:

#       --contention-profiling                                                                                                                             
#                 Enable lock contention profiling, if profiling is enabled
#       --profiling                                                                                                                                        
#                 Enable profiling via web interface host:port/debug/pprof/ (default true)

# Logging flags:

#       --add_dir_header                                                                                                                                   
#                 If true, adds the file directory to the header of the log messages
#       --alsologtostderr                                                                                                                                  
#                 log to standard error as well as files
#       --log_backtrace_at traceLocation                                                                                                                   
#                 when logging hits line file:N, emit a stack trace (default :0)
#       --log_dir string                                                                                                                                   
#                 If non-empty, write log files in this directory
#       --log_file string                                                                                                                                  
#                 If non-empty, use this log file
#       --log_file_max_size uint                                                                                                                           
#                 Defines the maximum size a log file can grow to. Unit is megabytes. If the value is 0, the maximum file size is unlimited. (default 1800)
#       --logtostderr                                                                                                                                      
#                 log to standard error instead of files (default true)
#       --one_output                                                                                                                                       
#                 If true, only write logs to their native severity level (vs also writing to each lower severity level)
#       --skip_headers                                                                                                                                     
#                 If true, avoid header prefixes in the log messages
#       --skip_log_headers                                                                                                                                 
#                 If true, avoid headers when opening log files
#       --stderrthreshold severity                                                                                                                         
#                 logs at or above this threshold go to stderr (default 2)
#   -v, --v Level                                                                                                                                          
#                 number for the log level verbosity
#       --vmodule moduleSpec                                                                                                                               
#                 comma-separated list of pattern=N settings for file-filtered logging