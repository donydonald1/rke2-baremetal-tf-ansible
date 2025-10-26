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
rke2_token: "${random_password.rke2_token.result}"
rke2_debug: true
rke2_wait_for_all_pods_to_be_ready: ${var.wait_for_all_pods_to_be_ready}
rke2_additional_sans: [
%{for item in local.all_sans~}
  "${item}"%{if index(local.all_sans, item) < length(local.all_sans) - 1}, %{endif}
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
  range-global: "${var.manager_rke2_loadbalancer_ip_range}"
  allow-share-range-global: "true"
  # allow-share-ingress-nginx: "true"
  allow-share-logging: "true"
  allow-share-monitoring: "true"
  allow-share-vpn: "true"

rke2_ha_mode_kubevip: true
rke2_kubevip_ipvs_lb_enable: ${var.kubevip_ipvs_lb_enable}

rke2_kubevip_cloud_provider_enable: ${var.kubevip_cloud_provider_enable}
rke2_kubevip_cloud_provider_image: ghcr.io/kube-vip/kube-vip-cloud-provider:${var.kubevip_cloud_provider_image_tag}
rke2_kubevip_svc_enable: ${var.kubevip_svc_enable}

rke2_version: "${var.rke2_version}"

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
    # "anonymous-auth=false",
    # "insecure-port=0",
    "enable-admission-plugins=NodeRestriction,PodSecurity",
    "admission-control-config-file=/etc/rancher/rke2/rke2-psa.yaml",
]
rke2_kube_controller_manager_arg:
  - "bind-address=127.0.0.1"
  - "node-monitor-period=4s"

# rke2_kube_scheduler_arg:
  # - "bind-address=0.0.0.0"

k8s_node_label: 
  - rke2_upgrade=true

rke2_kubelet_config:
  imageGCHighThresholdPercent: 80
  imageGCLowThresholdPercent: 70

rke2_kubelet_arg:
  - "fail-swap-on=false"
  - "cgroup-driver=systemd"
  - "max-pods=600"
  - "protect-kernel-defaults=true"
  # CPU and Memory reservations
  - "memory-manager-policy=Static"
  - "system-reserved=cpu=500m,memory=1Gi"
  - "kube-reserved=cpu=1200m,memory=1.5Gi"
  # Eviction policy
  - "eviction-hard=imagefs.available<5%,nodefs.available<5%"
  - "eviction-minimum-reclaim=imagefs.available=100Mi,nodefs.available=100Mi"
  - "max-pods=600"
  # - "anonymous-auth=false"
  # - "authorization-mode=Webhook"
  - "skip-log-headers=false"
  - "stderrthreshold=INFO"
  - "log-file-max-size=10"
  - "alsologtostderr=true"
  - "logtostderr=true"
  - "root-dir=/opt/rke2/kubelet"
  - "config=/etc/rancher/rke2/kubelet-config.yaml"

rke2_selinux: ${var.enable_rke2_selinux}
disable_kube_proxy: true
rke2_disable_cloud_controller: false
rke2_etcd_snapshot_schedule: "0 */6 * * *"
rke2_custom_manifests: 
  - "${path.module}/manifest/cilium.yaml"
  - "${path.module}/manifest/coredns.yaml"
  - "${path.module}/manifest/multus.yaml"
  - "${path.module}/manifest/generic-device-plugin.yaml"
  - "${path.module}/manifest/nodelocaldns.yaml"
  - "${path.module}/manifest/configmap-dns-proxy.yaml"
  - "${path.module}/manifest/prometheus-operator.yaml"
  - "${path.module}/manifest/nvidia-kubevirt-gpu-device-plugin.yaml"

rke2_server_options:
  - "private-registry: /etc/rancher/rke2/registries.yaml"
  - "pod-security-admission-config-file: /etc/rancher/rke2/rke2-psa.yaml"
  - "etcd-s3: ${var.enable_rke2_etcd_s3_backup}"
  - "etcd-s3-endpoint: ${var.s3_backup_endpoint}"
  - "etcd-s3-access-key: ${var.s3_backup_access_key}"
  - "etcd-s3-secret-key: ${var.s3_backup_secret_key}"
  - "etcd-s3-bucket: ${var.s3_backup_bucketname}"
  - "etcd-s3-region: ${var.s3_backup_region}"
  - "etcd-s3-folder: ${var.cluster_name}"
  - "etcd-snapshot-retention: ${var.etcd_snapshot_retention}"

rke2_cluster_cidr:
  - 10.42.0.0/16

rke2_service_cidr:
  - 10.43.0.0/16

# rke2_ingress_controller: ${var.ingress_controller_name != "" ? var.ingress_controller_name : "nginx"}

EOT
}
# - "${path.module}/manifest/rke2-cilium.yaml"
