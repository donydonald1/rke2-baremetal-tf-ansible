variable "vm_timezone" {
  description = "Timezone for the VM"
  type        = string
  default     = "America/Chicago"
}

variable "rhsm_username" {
  description = "Red Hat Subscription Manager (RHSM) username. Required if is_rhel is true."
  type        = string
  default     = null
  sensitive   = true
  validation {
    condition     = var.is_rhel ? var.rhsm_username != null && var.rhsm_username != "" : true
    error_message = "rhsm_username is required when is_rhel is set to true."
  }
}

variable "rhsm_password" {
  description = "Red Hat Subscription Manager (RHSM) password. Required if is_rhel is true."
  type        = string
  default     = null
  sensitive   = true
  validation {
    condition     = var.is_rhel ? var.rhsm_password != null && var.rhsm_password != "" : true
    error_message = "rhsm_password is required when is_rhel is set to true."
  }
}

variable "is_rhel" {
  description = "Whether the OS is RHEL"
  type        = bool
  default     = false

}

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


variable "ssh_private_key" {
  description = "SSH private Key"
  type        = string
}

variable "ssh_port" {
  description = "SSH port"
  type        = number
  default     = 22
}


variable "ssh_public_key" {
  description = "SSH public Key"
  type        = string
}

variable "vm_user" {
  description = "Default user for the VM"
  type        = string
  default     = "rke2"
}

variable "ssh_authorized_keys" {
  description = "List of ssh authorized key entry to add to the vm."
  type        = list(string)

}

###############################NOTE - RKE2 Config   ####################################

variable "cluster_config_values" {
  description = "YAML configuration for the RKE2 cluster"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Name of the RKE2 cluster"
  type        = string
  default     = "rke2-cluster"
}

variable "rke2_version" {
  description = "Version of RKE2 to install"
  type        = string
  default     = "v1.31.5+rke2r1"
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
  default     = "stable"
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
variable "rancher_helmchart_bootstrap" {
  type        = bool
  default     = true
  description = "Whether the HelmChart rancher shall be run on control-plane nodes."
}

variable "enable_vault" {
  type        = bool
  default     = true
  description = "Whether to enable Vault."

}

variable "vault_admin_password" {
  type        = string
  default     = "Techsecoms-@rke2"
  description = "The password for the Vault admin user. If not set, a random password will be generated."
  sensitive   = true
}

variable "vault_admin_username" {
  type        = string
  default     = "admin"
  description = "The username for the Vault admin user."

}

variable "enable_argocd" {
  type        = bool
  default     = true
  description = "Whether to enable ArgoCD."

}

variable "enable_kube-vip-lb" {
  type        = bool
  default     = true
  description = "Whether to enable kube-vip."
}

variable "enable_external_dns" {
  type        = bool
  default     = true
  description = "Whether to enable External DNS."

}

variable "enable_external_secrets" {
  type        = bool
  default     = true
  description = "Whether to enable External Secrets."

}

variable "rancher_registration_manifest_url" {
  type        = string
  description = "The url of a rancher registration manifest to apply. (see https://rancher.com/docs/rancher/v2.6/en/cluster-provisioning/registered-clusters/)."
  default     = ""
  sensitive   = true
}

variable "enable_rancher" {
  type        = bool
  default     = true
  description = "Whether to enable Rancher."

}

variable "sys_upgrade_controller_version" {
  type        = string
  default     = "v0.14.2"
  description = "Version of the System Upgrade Controller for automated upgrades of rke2. See https://github.com/rancher/system-upgrade-controller/releases for the available versions."
}

variable "cert_manager_values" {
  type        = string
  default     = <<EOT
crds:
  enabled: true
  keep: true
  EOT
  description = "Additional helm values file to pass to Cert-Manager as 'valuesContent' at the HelmChart. Warning, the default value is only valid from cert-manager v1.15.0 onwards. For older versions, you need to set 'installCRDs: true'."
}

variable "argocd_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to ArgoCD as 'valuesContent' at the HelmChart."
}

variable "argocd_hostname" {
  type        = string
  default     = ""
  description = "The hostname for the ArgoCD server. If not set, the IP address of the first control plane node will be used."

  validation {
    condition     = var.enable_argocd == false || (var.enable_argocd == true && var.argocd_hostname != "")
    error_message = "If enable_argocd is set to true, argocd_hostname must be provided and cannot be empty."
  }
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

variable "argocd_admin_password" {
  type        = string
  default     = "$2a$10$kL.eMVfvDRySAkP7lpIpduP9gVb9fuDajLCbPZk8Rr73Ij3i7vAQabrew#"
  description = "The password for the ArgoCD admin user. If not set, a random password will be generated."

}

variable "vault_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Vault as 'valuesContent' at the HelmChart."

}

variable "vault_hostname" {
  type        = string
  default     = "vault-prod.techsecoms.com"
  description = "The hostname for the Vault server. If not set, the IP address of the first control plane node will be used."

  validation {
    condition     = var.enable_vault == false || (var.enable_vault == true && var.vault_hostname != "")
    error_message = "If enable_vault is set to true, vault_hostname must be provided and cannot be empty."
  }

}

variable "vault_storage_class" {
  type        = string
  default     = "vsphere"
  description = "The storage class for the Vault server."

}

variable "rancher_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to Rancher as 'valuesContent' at the HelmChart."

}

variable "rancher_admin_password" {
  type        = string
  default     = ""
  description = "The admin password for Rancher"
  sensitive   = true

}

variable "rancher_bootstrap_password" {
  type        = string
  default     = ""
  description = "The password for the Rancher bootstrap user. If not set, a random password will be generated."

}

variable "ingress_class" {
  type        = string
  default     = "nginx"
  description = "The ingress class to use for the ingress controller."

}


variable "external_secrets_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to External Secrets as 'valuesContent' at the HelmChart."

}

variable "external_dns_values" {
  type        = string
  default     = ""
  description = "Additional helm values file to pass to External DNS as 'valuesContent' at the HelmChart."

}

variable "cloudflare_api_key" {
  type        = string
  default     = ""
  description = "The Cloudflare API key for External DNS."

}

variable "cloudflare_email" {
  type        = string
  default     = ""
  description = "The Cloudflare email for External DNS."

}

variable "cloudflare_proxied" {
  type        = bool
  default     = false
  description = "Whether to use Cloudflare proxy for External DNS."

}

variable "domain" {
  type        = string
  default     = "techsecoms.com"
  description = "The domain for the cluster."

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

variable "create_kubeconfig" {
  description = "Whether to create a kubeconfig file."
  type        = bool
  default     = true
}

variable "vault_wait_time" {
  description = "Time to wait for vault to become available"
  type        = string
  default     = "90s"

}

variable "wait" {
  description = "An optional wait before installing the Rancher helm chart (seconds)"
  default     = "90s"
}

variable "nginx_values" {
  description = "Additional helm values file to pass to Nginx as 'valuesContent' at the HelmChart."
  type        = string
  default     = ""
}

variable "manager_rke2_loadbalancer_ip_range" {
  description = "The IP range for the RKE2 loadbalancer."
  type        = string
  default     = ""
}



variable "additional_sans" {
  description = "Additional SAN entries for RKE2"
  type        = list(string)
  default     = []
}

variable "private_registry_url" {
  type        = string
  default     = ""
  description = "The URL of the private registry."
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

variable "ansible_hosts_group" {
  description = "Ansible hosts group to target"
  type        = string
  default     = "all"
}

variable "manager-nginx-lb-ip" {
  description = "The IP address for the manager nginx loadbalancer."
  type        = string
  default     = ""
}
