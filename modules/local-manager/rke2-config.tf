locals {
  cluster_config_values = var.cluster_config_values != "" ? var.cluster_config_values : <<EOT
rke2_airgap_mode: false
rke2_ha_mode: true
rke2_ha_mode_keepalived: false
rke2_api_ip: ${var.manager_rke2_api_ip}
rke2_token: "${random_password.rke2_token.result}"
rke2_debug: true
rke2_wait_for_all_pods_to_be_ready: true
rke2_additional_sans: [
%{for item in local.all_sans~}
  "${item}"%{if index(local.all_sans, item) < length(local.all_sans) - 1}, %{endif}
%{endfor~}
]
rke2_download_kubeconf: true
rke2_download_kubeconf_file_name: "${var.cluster_name}-kubeconfig.yaml"
rke2_download_kubeconf_path: "${path.cwd}/"
rke2_cluster_group_name: "${var.cluster_name}"
rke2_channel: "stable"
rke2_cis_profile: "cis"
rke2_kubevip_image: ghcr.io/kube-vip/kube-vip:v0.8.9
rke2_loadbalancer_ip_range: 
  range-global: "${var.manager_rke2_loadbalancer_ip_range}"
rke2_ha_mode_kubevip: true
rke2_kubevip_ipvs_lb_enable: true
rke2_kubevip_cloud_provider_enable: true
rke2_kubevip_cloud_provider_image: ghcr.io/kube-vip/kube-vip-cloud-provider:v0.0.11
rke2_kubevip_svc_enable: true
rke2_version: "${var.rke2_version}"
rke2_cni:
  - multus
  - calico
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
k8s_node_label: 
  - rke2_upgrade=true

rke2_kubelet_arg:
  - "--system-reserved=cpu=0,memory=0"
  - "--kube-reserved=cpu=0,memory=0"
  - "--eviction-hard=memory.available<500Mi,nodefs.available<10%"
  - "--cloud-provider=external"
  - "cgroup-driver=systemd"
  - "max-pods=300"
  - "skip-log-headers=false"
  - "stderrthreshold=INFO"
  - "log-file-max-size=10"
  - "alsologtostderr=true"
  - "logtostderr=true"
  - "protect-kernel-defaults=true"
rke2_selinux: true
rke2_kube_proxy_arg:
  - "proxy-mode=ipvs"
  - "ipvs-strict-arp=true"
  - "ipvs-scheduler=rr"
  - "ipvs-tcp-timeout=120s"
  - "ipvs-udp-timeout=120s"
  - "ipvs-tcpfin-timeout=1m"
rke2_cloud_provider_name: "rancher-vsphere"
rke2_disable_cloud_controller: true
# rke2_custom_manifests: "${path.module}/manifest"
rke2_server_options:
  - "cloud-provider-config: /var/lib/rancher/rke2/server/manifests/config-rancher-vsphere-cpi-csi.yaml"
  - "private-registry: /etc/rancher/rke2/registries.yaml"
EOT
}
