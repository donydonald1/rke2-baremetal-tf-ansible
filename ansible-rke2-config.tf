locals {
  ansible_hosts_group = var.ansible_hosts_group != "" ? var.ansible_hosts_group : "all"
  all_sans = concat(
    flatten([module.rke2_metalhost_servers.server_ips]),
    flatten([module.rke2_metalhost_servers.server_names]),
    flatten([var.manager_rke2_api_dns]),
    flatten([var.manager_rke2_api_ip]),
  )

  cluster_config_values = var.cluster_config_values != "" ? var.cluster_config_values : <<EOT
rke2_airgap_mode: false
rke2_ha_mode: true
rke2_ha_mode_keepalived: false
rke2_api_ip: ${var.manager_rke2_api_ip}
rke2_token: ${random_password.rke2_token.result}
rke2_debug: true
rke2_wait_for_all_pods_to_be_ready: ${var.wait_for_all_pods_to_be_ready}
rke2_additional_sans: [
%{for item in local.all_sans~}
  ${item}%{if index(local.all_sans, item) < length(local.all_sans) - 1}, %{endif}
%{endfor~}
]
rke2_download_kubeconf: true
rke2_download_kubeconf_file_name: "${var.cluster_name}-kubeconfig.yaml"
rke2_download_kubeconf_path: "${path.cwd}/"
rke2_cluster_group_name: ${var.cluster_name}
rke2_channel: stable
rke2_cis_profile: "cis"
rke2_kubevip_image: ghcr.io/kube-vip/kube-vip:${var.kubevip_version}

rke2_loadbalancer_ip_range: 
  range-global: ${var.manager_rke2_loadbalancer_ip_range}
  allow-share-range-global: "true"
  # allow-share-ingress-nginx: "true"
  allow-share-logging: "true"
  allow-share-monitoring: "true"
  allow-share-vpn: "true"

rke2_ha_mode_kubevip: true
rke2_kubevip_ipvs_lb_enable: true
# rke2_api_cidr: 24
rke2_kubevip_cloud_provider_enable: true
rke2_kubevip_cloud_provider_image: ghcr.io/kube-vip/kube-vip-cloud-provider:${var.kubevip_cloud_provider_image_tag}
rke2_kubevip_svc_enable: true
# rke2_kubevip_metrics_port: 2112
rke2_version: ${var.rke2_version}
# rke2_apiserver_dest_port: 6443
# rke2_interface: enp0s31f6
rke2_kubevip_args:
  - param: lb_enable
    value: true
  - param: lb_port
    value: 6443
rke2_cni:
  - multus
  - cilium
rke2_disable:
  - rke2-ingress-nginx

rke2_kube_apiserver_args: [
    "audit-policy-file=/etc/rancher/rke2/audit-policy.yaml",
    "audit-log-path=/var/log/rancher/audit.log",
    "audit-log-maxage=30",
    "audit-log-mode=blocking-strict",
    "audit-log-maxage=30",
    "admission-control-config-file=/etc/rancher/rke2/rke2-psa.yaml",
]
rke2_kube_controller_manager_arg:
  - "bind-address=0.0.0.0"
  - "node-monitor-period=4s"

rke2_kube_scheduler_arg:
  - "bind-address=0.0.0.0"

k8s_node_label: 
  - rke2_upgrade=true

rke2_kubelet_config:
  imageGCHighThresholdPercent: 80
  imageGCLowThresholdPercent: 70

rke2_kubelet_arg:
  # - "kube-reserved=cpu=0.5,memory=1Gi,ephemeral-storage=1Gi"
  # - "system-reserved=cpu=2,memory=10Gi,ephemeral-storage=1Gi"
  - "eviction-hard=memory.available<300Mi,nodefs.available<10%"
  - "cgroup-driver=systemd"
  - "max-pods=600"
  - "skip-log-headers=false"
  - "stderrthreshold=INFO"
  - "log-file-max-size=10"
  - "alsologtostderr=true"
  - "logtostderr=true"
  - "protect-kernel-defaults=true"
  - "--config=/etc/rancher/rke2/kubelet-config.yaml"

rke2_selinux: true
disable_kube_proxy: true
rke2_disable_cloud_controller: false

rke2_custom_manifests: 
  - "${path.root}/manifest/cilium.yaml"
  - "${path.root}/manifest/coredns.yaml"
  - "${path.root}/manifest/multus.yaml"
  - "${path.root}/manifest/generic-device-plugin.yaml"
  - "${path.root}/manifest/nodelocaldns.yaml"
  - "${path.root}/manifest/configmap-dns-proxy.yaml"
  - "${path.root}/manifest/nvidia-kubevirt-gpu-device-plugin.yaml"

rke2_server_options:
  - "private-registry: /etc/rancher/rke2/registries.yaml"

rke2_cluster_cidr:
  - 10.42.0.0/16
rke2_service_cidr:
  - 10.43.0.0/16

rke2_etcd_snapshot_s3_options:
  etcd-s3: ${var.enable_rke2_etcd_s3_backup}
  s3_endpoint: ${var.s3_backup_endpoint}
  access_key: ${var.s3_backup_access_key}
  secret_key: ${var.s3_backup_secret_key}
  bucket: ${var.s3_backup_bucketname}
  snapshot_name: ${var.snapshot_name}
  etcd-snapshot-retention: ${var.etcd_snapshot_retention}
  etcd-snapshot-schedule-cron: ${var.etcd_snapshot_schedule_cron}
  skip_ssl_verify: ${var.s3_backup_skip_ssl_verify} 
  endpoint_ca: "" 
  region: "" 
  folder: ${var.cluster_name}

# rke2_ingress_controller: ingress-nginx
# rke2_ingress_nginx_values:
#   controller:
#     kind: Deployment
#     admissionWebhooks:
#       enabled: enable
#       timeoutSeconds: 30
#     allowSnippetAnnotations: true
#     replicaCount: 3
#     # extraArgs:
#     #   # Disable until PR merged: https://github.com/kubernetes/ingress-nginx/pull/12626
#     #   enable-annotation-validation: "false"

#     service:
#       enabled: true

#       annotations:
#         ${var.enable_kube-vip-lb ? "kube-vip.io/loadbalancerIPs: \"${var.kube-vip-nginx-lb-ip}\"" : ""}
#       loadBalancerClass: "kube-vip.io/kube-vip-class"
#       externalTrafficPolicy: Local
#       enableHttp: true
#       enableHttps: true
#       ports:
#         http: 80
#         https: 443

#       targetPorts:
#         http: http
#         https: https

#       type: LoadBalancer
#     addHeaders:
#       Referrer-Policy: strict-origin-when-cross-origin
#     config:
#       # auto value takes all nodes in cgroups v2 (dell_v2)
#       worker-processes: 1
#       hsts: "true"
#       http-snippet: |
#         proxy_cache_path /dev/shm levels=1:2 keys_zone=static-cache:2m max_size=300m inactive=7d use_temp_path=off;
#         proxy_cache_key $scheme$proxy_host$request_uri;
#         proxy_cache_lock on;
#         proxy_cache_use_stale updating;
#       hsts-include-subdomains: "false"
#       hsts-max-age: "63072000"
#       server-name-hash-bucket-size: "256"
#       client-body-buffer-size: "${var.nginx_client_body_buffer_size}"
#       client-max-body-size: "${var.nginx_client_max_body_size}"
#       use-http2: "true"
#       ssl-ciphers: "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4"
#       ssl-protocols: "TLSv1.3 TLSv1.2"
#       server-tokens: "false"
#       # Configure smaller defaults for upstream-keepalive-*, see https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration
#       upstream-keepalive-connections: 100 # Limit of 100 held-open connections
#       upstream-keepalive-time:        30s # 30 second limit for connection reuse
#       upstream-keepalive-timeout:       5 # 5 second timeout to hold open idle connections
#       upstream-keepalive-requests:   1000 # 1000 requests per connection, before recycling
#       brotli-level: "6"
#       brotli-types: "text/xml image/svg+xml application/x-font-ttf image/vnd.microsoft.icon application/x-font-opentype application/json font/eot application/vnd.ms-fontobject application/javascript font/otf application/xml application/xhtml+xml text/javascript application/x-javascript text/plain application/x-font-truetype application/xml+rss image/x-icon font/opentype text/css image/x-win-bitmap"
#       enable-real-ip: "true"
#       ignore-invalid-headers: "false"
#       use-forwarded-headers: true
#       allow-snippet-annotations: true
#       annotations-risk-level: Critical

#     ingressClassResource:
#       name: nginx
#       enabled: true
#       default: true
#       # controllerValue: "k8s.io/ingress-nginx"

#     ingressClass: nginx

#     resources:
#       limits:
#         memory: 328Mi
#       requests:
#         cpu: 40m
#         memory: 150Mi

#     extraVolumeMounts:
#       - name: dshm
#         mountPath: /dev/shm

#     metrics:
#       enabled: false
#       serviceMonitor:
#         enabled: false
#         additionalLabels:
#           release: monitoring

#     extraVolumes:
#       - name: dshm
#         emptyDir:
#           medium: Memory
#           # not working until v1.21? https://github.com/kubernetes/kubernetes/issues/63126
#           sizeLimit: 303Mi

#       - name: dns-proxy-config-volume
#         configMap:
#           name: dns-proxy-config

#     # dnsPolicy: None
#     # dnsConfig:
#     #   nameservers:
#     #     - 127.0.0.1
#     #     - 1.1.1.1
#     #     - 8.8.8.8
#     #   searches:
#     #     - rke2-ingress-nginx-controller.svc.cluster.local
#     #     - svc.cluster.local
#     #     - cluster.local
#     extraContainers:
#       - name: dns-proxy
#         image: coredns/coredns:1.12.3
#         args:
#           - -conf
#           - /etc/coredns/Corefile
#         volumeMounts:
#           - mountPath: /etc/coredns
#             name: dns-proxy-config-volume
#             readOnly: true
#         livenessProbe:
#           failureThreshold: 5
#           httpGet:
#             path: /health
#             port: 8080
#             scheme: HTTP
#           initialDelaySeconds: 60
#           periodSeconds: 10
#           successThreshold: 1
#           timeoutSeconds: 5
#         readinessProbe:
#           failureThreshold: 3
#           httpGet:
#             path: /health
#             port: 8080
#             scheme: HTTP
#           periodSeconds: 10
#           successThreshold: 1
#           timeoutSeconds: 1
#         resources:
#           limits:
#             memory: 128Mi
#           requests:
#             cpu: 10m
#             memory: 13Mi
#         securityContext:
#           allowPrivilegeEscalation: false
#           capabilities:
#             add:
#               - NET_BIND_SERVICE
#             drop:
#               - all
#           readOnlyRootFilesystem: true
#   scope:
#     enabled: true
#   tcp:
#     22: "gitlab/gitlab-gitlab-shell:22"
#   # udp:
#   #   ${var.wireguard_port}: "vpn/wireguard:${var.wireguard_port}"
EOT
}
# - "${path.module}/manifest/rke2-cilium.yaml"
