variable "baremetal_servers" {
  description = "List of bare-metal servers with name and IP"
  type = list(object({
    name = string
    ip   = string
  }))

  // Optional: guard that IPs look like IPv4
  validation {
    condition     = alltrue([for s in var.baremetal_servers : can(regex("^((25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)\\.){3}(25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)$", s.ip))])
    error_message = "Each server.ip must be a valid IPv4 address."
  }
}

variable "private_registry_url" {
  type        = string
  default     = ""
  description = "The URL of the private registry."
}

variable "kubevip_version" {
  type        = string
  default     = "v0.9.2"
  description = "The image tag for the Kube-VIP container."
}

variable "kubevip_cloud_provider_image_tag" {
  type        = string
  default     = "v0.0.12"
  description = "The image tag for the Kube-VIP cloud provider container."
}
variable "private_registry_username" {
  type        = string
  default     = ""
  description = "The username for the private registry."
}

variable "private_registry_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "The password for the private registry."
}

variable "private_registry_insecure_skip_verify" {
  type        = bool
  default     = true
  description = "Whether to skip the verification of the private registry."
}

variable "private_registries" {
  description = "RKE2 registries.yml contents. It used to access private docker registries."
  default     = ""
  type        = string
}

variable "dockerhub_registry_auth_username" {
  type        = string
  default     = ""
  description = "The username for the DockerHub registry."

}

variable "dockerhub_registry_auth_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "The password for the DockerHub registry."
}

variable "ssh_user" {
  description = "SSH user for bare-metal servers"
  type        = string
  default     = "root"
}

variable "ssh_private_key_file" {
  description = "SSH private key file for bare-metal servers"
  type        = string
  default     = ""
}

variable "ssh_port" {
  description = "SSH port for bare-metal servers"
  type        = number
  default     = 22
}

variable "rancher_bootstrap_password" {
  type        = string
  default     = ""
  description = "The password for the Rancher bootstrap user. If not set, a random password will be generated."

}

variable "cluster_name" {
  description = "Name of the RKE2 cluster"
  type        = string
  default     = "rke2-cluster"
}

variable "ansible_hosts_group" {
  description = "Ansible hosts group to target"
  type        = string
  default     = "all"
}

variable "manager_rke2_api_dns" {
  type        = string
  default     = "10.10.0.23"
  description = "The IP address for the RKE2 API. If not set, the IP address of the first control plane node will be used."
}

variable "manager_rke2_api_ip" {
  type        = string
  default     = "10.10.0.23"
  description = "The IP address for the RKE2 API. If not set, the IP address of the first control plane node will be used."
}

variable "enable_rke2_cluster_api" {
  description = "Whether to enable kube-vip"
  type        = bool
  default     = false

  validation {
    condition = (
      !var.enable_rke2_cluster_api || (
        var.manager_rke2_api_ip != null && var.manager_rke2_api_ip != "" &&
        var.manager_rke2_api_dns != null && var.manager_rke2_api_dns != ""
      )
    )
    error_message = "If enable_kube_vip is true, both kube_vip_ip and kube_vip_dns must be provided and cannot be empty."
  }
}

variable "cluster_config_values" {
  description = "YAML configuration for the RKE2 cluster"
  type        = string
  default     = ""
}

variable "manager_rke2_loadbalancer_ip_range" {
  description = "The IP range for the RKE2 loadbalancer."
  type        = string
  default     = ""
}

variable "rke2_version" {
  description = "Version of RKE2 to install"
  type        = string
  default     = "v1.31.5+rke2r1"
}
variable "create_kubeconfig" {
  description = "Create a kubeconfig file"
  type        = bool
  default     = true
}

variable "kube-vip-nginx-lb-ip" {
  description = "The IP address for the kube-vip nginx loadbalancer."
  type        = string
  default     = ""
}

variable "enable_kube-vip-lb" {
  description = "Whether to enable kube-vip load balancer"
  type        = bool
  default     = false
  validation {
    condition = (
      !var.enable_kube-vip-lb || (
        var.kube-vip-nginx-lb-ip != null && var.kube-vip-nginx-lb-ip != ""
      )
    )
    error_message = "If enable_kube-vip-lb is true, kube-vip-nginx-lb-ip must be provided and cannot be empty."
  }
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  default     = ""
}

variable "domain" {
  type        = string
  default     = "techsecom.io"
  description = "The Cloudflare zone/domain name."
}

variable "cloudflare_email" {
  description = "Cloudflare account email"
  type        = string
  default     = ""
}

variable "cloudflare_api_key" {
  description = "Cloudflare API key"
  type        = string
  default     = ""
}

variable "s3_backup_access_key" {
  description = "The access key for the S3 backup."
  type        = string
  default     = ""
  sensitive   = true
}

variable "s3_backup_secret_key" {
  description = "The secret key for the S3 backup."
  type        = string
  default     = ""
  sensitive   = true
}

variable "s3_backup_endpoint" {
  description = "The endpoint for the S3 backup."
  type        = string
  default     = ""
}

variable "s3_backup_bucketname" {
  description = "The bucket for the S3 backup."
  type        = string
  default     = ""
}

variable "snapshot_name" {
  description = "The name of the snapshot."
  type        = string
  default     = ""
}

variable "s3_backup_skip_ssl_verify" {
  description = "Whether to skip the SSL verification for the S3 backup."
  type        = bool
  default     = false
}

variable "cloudflared_values" {
  description = "YAML configuration for the Cloudflared"
  type        = string
  default     = ""
}

variable "external_dns_values" {
  description = "YAML configuration for the External DNS"
  type        = string
  default     = ""
}

variable "external_secrets_values" {
  description = "YAML configuration for the External Secrets"
  type        = string
  default     = ""
}

variable "rancher_values" {
  description = "YAML configuration for the Rancher"
  type        = string
  default     = ""
}

variable "vault_operator_values" {
  description = "YAML configuration for the Vault Operator"
  type        = string
  default     = ""
}

variable "argocd_values" {
  description = "YAML configuration for ArgoCD"
  type        = string
  default     = ""
}

variable "cert_manager_values" {
  description = "YAML configuration for Cert Manager"
  type        = string
  default     = ""
}

variable "enable_argocd" {
  description = "Whether to enable ArgoCD"
  type        = bool
  default     = false
}

variable "argocd_hostname" {
  description = "The hostname for ArgoCD"
  type        = string
  default     = ""
}

variable "argocd_admin_password" {
  description = "The admin password for ArgoCD"
  type        = string
  default     = ""
}

variable "argocd_iodc_issuer_url" {
  type        = string
  default     = ""
  description = "The OIDC issuer URL for the ArgoCD OIDC configuration."

}

variable "argocd_oidc_client_id" {
  type        = string
  default     = ""
  description = "The ArgoCD OIDC client ID."

}

variable "argocd_oidc_client_secret" {
  type        = string
  default     = ""
  description = "The ArgoCD OIDC client secret."

}

variable "argocd_tamplate_repo_url" {
  type        = string
  default     = ""
  description = "The URL of the ArgoCD Application Template repository."

}

variable "argocd_github_app_id" {
  type        = string
  default     = ""
  description = "The GitHub App ID for the ArgoCD Application Template repository."

}

variable "argocd_github_app_installation_id" {
  type        = string
  default     = ""
  description = "The GitHub App Installation ID for the ArgoCD Application Template repository."

}

variable "argocd_github_app_private_key" {
  type        = string
  default     = ""
  description = "The GitHub App Private Key for the ArgoCD Application Template repository."

}

variable "enable_rancher" {
  type        = bool
  default     = false
  description = "Whether to enable Rancher."
}

variable "rancher_hostname" {
  type        = string
  default     = ""
  description = "The hostname for the Rancher server. If not set, the IP address of the first control plane node will be used."

  validation {
    condition     = var.enable_rancher == false || (var.enable_rancher == true && var.rancher_hostname != "")
    error_message = "If enable_rancher is set to true, rancher_hostname must be provided and cannot be empty."
  }
}

variable "rancher_install_channel" {
  type        = string
  default     = "latest"
  description = "The rancher installation channel."

  validation {
    condition     = contains(["stable", "latest"], var.rancher_install_channel)
    error_message = "The allowed values for the Rancher install channel are stable or latest."
  }
}

variable "rancher_version" {
  type        = string
  default     = "*"
  description = "Version of rancher."
}

variable "rancher_registration_manifest_url" {
  type        = string
  description = "The url of a rancher registration manifest to apply. (see https://rancher.com/docs/rancher/v2.6/en/cluster-provisioning/registered-clusters/)."
  default     = ""
  sensitive   = true
}

variable "rancher_helmchart_bootstrap" {
  type        = bool
  default     = true
  description = "Whether the HelmChart rancher shall be run on control-plane nodes."
}

variable "ingress_class" {
  type        = string
  default     = ""
  description = "The ingress class to use for the Rancher server."
}

variable "enable_cert_manager" {
  type        = bool
  default     = true
  description = "Enable cert manager."
}

variable "cert_manager_version" {
  type        = string
  default     = "*"
  description = "Version of cert_manager."
}

variable "cert_manager_helmchart_bootstrap" {
  type        = bool
  default     = false
  description = "Whether the HelmChart cert_manager shall be run on control-plane nodes."
}

variable "initial_rke2_channel" {
  type        = string
  default     = "stable" # Please update kube.tf.example too when changing this variable
  description = "Allows you to specify an initial rke2 channel. See https://update.rke2.io/v1-release/channels for available channels."

  validation {
    condition     = contains(["stable", "latest", "testing", "v1.16", "v1.17", "v1.18", "v1.19", "v1.20", "v1.21", "v1.22", "v1.23", "v1.24", "v1.25", "v1.26", "v1.27", "v1.28", "v1.29", "v1.30", "v1.31", "v1.32", "v1.33"], var.initial_rke2_channel)
    error_message = "The initial rke2 channel must be one of stable, latest or testing, or any of the minor kube versions like v1.26."
  }
}

variable "system_upgrade_enable_eviction" {
  type        = bool
  default     = true
  description = "Whether to directly delete pods during system upgrade (rke2) or evict them. Defaults to true. Disable this on small clusters to avoid system upgrades hanging since pods resisting eviction keep node unschedulable forever. NOTE: turning this off, introduces potential downtime of services of the upgraded nodes."
}

variable "system_upgrade_use_drain" {
  type        = bool
  default     = true
  description = "Wether using drain (true, the default), which will deletes and transfers all pods to other nodes before a node is being upgraded, or cordon (false), which just prevents schedulung new pods on the node during upgrade and keeps all pods running"
}

variable "enable_external_secrets" {
  type        = bool
  default     = false
  description = "Whether to enable External Secrets."
}

variable "enable_external_dns" {
  type        = bool
  default     = false
  description = "Whether to enable External DNS."
}

variable "sys_upgrade_controller_version" {
  type        = string
  default     = "v0.16.2"
  description = "Version of the System Upgrade Controller for automated upgrades of rke2. See https://github.com/rancher/system-upgrade-controller/releases for the available versions."
}

variable "argocd_project_names" {
  description = "List of ArgoCD project names"
  type        = list(string)
  default     = ["system", "platform", "infrastructure", "monitoring", "main"]
}

variable "vault_organization" {
  description = "The organization for the Vault server."
  type        = string
  default     = "Techsecom Consulting Group"
}

variable "vault_oidc_discovery_url" {
  type        = string
  default     = ""
  description = "The OIDC discovery URL for the Vault OIDC configuration."
  sensitive   = true
}

variable "vault_oidc_client_id" {
  type        = string
  default     = ""
  description = "The Vault OIDC client ID."
  sensitive   = true
}

variable "vault_oidc_client_secret" {
  type        = string
  default     = ""
  description = "The Vault OIDC client secret."
  sensitive   = true
}

variable "longhorn_values" {
  description = "YAML configuration for Longhorn"
  type        = string
  default     = ""
}

variable "longhorn_version" {
  type        = string
  default     = "*"
  description = "Version of longhorn."
}

variable "longhorn_helmchart_bootstrap" {
  type        = bool
  default     = false
  description = "Whether the HelmChart longhorn shall be run on control-plane nodes."
}

variable "longhorn_repository" {
  type        = string
  default     = "https://charts.longhorn.io"
  description = "By default the official chart which may be incompatible with rancher is used. If you need to fully support rancher switch to https://charts.rancher.io."
}

variable "longhorn_namespace" {
  type        = string
  default     = "longhorn-system"
  description = "Namespace for longhorn deployment, defaults to 'longhorn-system'"
}

variable "enable_longhorn" {
  type        = bool
  default     = true
  description = "Whether to enable Longhorn."
}

variable "longhorn_fstype" {
  type        = string
  default     = "ext4"
  description = "Filesystem type for the NFS mount to be used by Longhorn. Common values are 'xfs' and 'ext4'. Ensure that the NFS server supports the chosen filesystem type."
}

variable "enable_csi-driver-nfs" {
  type        = bool
  default     = true
  description = "Whether to enable CSI Driver NFS."
}

variable "csi-driver-nfs_values" {
  description = "YAML configuration for the CSI Driver NFS"
  type        = string
  default     = ""
}

variable "enable_csi_driver_nfs" {
  type        = bool
  default     = true
  description = "Whether to enable CSI Driver NFS."
}

variable "vault_secrets" {
  type = map(object({
    path = string
    data = map(string)
  }))
  description = "Map of vault secrets to manage."
  default = {
  }
}

variable "rancher_admin_password" {
  type        = string
  default     = ""
  description = "The admin password for Rancher"
  sensitive   = true

}

variable "is_rhel" {
  type    = bool
  default = true
}

variable "rhsm_username" {
  description = "Red Hat Subscription Manager username"
  type        = string
  default     = ""
}
variable "rhsm_password" {
  description = "Red Hat Subscription Manager password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "csi_driver_nfs_subdir" {
  type        = string
  default     = "$${pvc.metadata.namespace}/$${pvc.metadata.name}/$${pv.metadata.name}"
  description = "The subdirectory on the NFS server to use for the CSI Driver NFS."
}

variable "nfs_server_ip" {
  description = "NFS server IP address"
  type        = string
  default     = ""
}

variable "nfsver" {
  description = "NFS protocol version to use (3 or 4.1)"
  type        = number
  default     = 3
  validation {
    condition     = contains([3, 4.1], var.nfsver)
    error_message = "nfsver must be 3 or 4.1."
  }
}

variable "csi_driver_nfs_localpath_values" {
  description = "YAML configuration for the CSI Driver NFS Local Path Provisioner"
  type        = string
  default     = ""
}

variable "nfs_mount_point" {
  description = "Where to mount the NFS export on the host"
  type        = string
  default     = "/mnt/nfs"
}

variable "nfs_shared_dir" {
  description = "NFS subdirectory for the shared directory"
  type        = string
  default     = ""
}
