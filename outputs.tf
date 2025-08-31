output "server_names" {
  value = module.rke2_mater_servers.server_names
}

output "servers_ips" {
  value = module.rke2_mater_servers.server_ips
}

output "servers_by_name" {
  value = { for server in module.rke2_mater_servers.servers_by_name : server.name => server.ip }
}

output "rke2_private_registries" {
  description = "Decoded registries.yaml content"
  value       = module.rke2_mater_servers.rke2_private_registries
  sensitive   = true

}

######################################NOTE - Manager Cluster Configuration####################################
output "client_key" {
  description = "Client key for Kubernetes cluster authentication"
  value       = module.kubeconfig.kubeconfig_client_key
  sensitive   = true
  depends_on  = [module.kubeconfig]
}

output "cluster_ca_certificate" {
  description = "CA certificate for the Kubernetes cluster"
  value       = module.kubeconfig.kubeconfig_cluster_ca_certificate
  depends_on  = [module.kubeconfig]
  sensitive   = true
}

output "host" {
  description = "Host for Kubernetes cluster"
  value       = module.kubeconfig.kubeconfig_host
  depends_on  = [module.kubeconfig]
  sensitive   = true
}

output "client_certificate" {
  description = "Client certificate for Kubernetes cluster authentication"
  value       = module.kubeconfig.kubeconfig_client_certificate
  sensitive   = true
  depends_on  = [module.kubeconfig]
}


output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = module.kubeconfig.kubeconfig_cluster_name
  depends_on  = [module.kubeconfig]

}

output "kubeconfig_file" {
  description = "Kubeconfig file content with external IP address"
  value       = module.kubeconfig.kubeconfig_file
  sensitive   = true
}

# output "cloudflare_api_token" {
#   value     = module.cloudflare.cloudflare_api_token
#   sensitive = true

# }

# output "all_namespaces" {
#   value = data.kubernetes_all_namespaces.all.namespaces
# }

# output "tunnel_id" {
#   value = module.cloudflare.tunnel_id

# }

# output "vault_root_token" {
#   value       = length(data.kubernetes_secret_v1.vault_seal) > 0 ? lookup(data.kubernetes_secret_v1.vault_seal.data, "vault-root", null) : null
#   sensitive   = true
#   description = "The root token for Vault"
# }

output "domain_name" {
  value       = var.domain
  description = "The domain name for the Kubernetes cluster"
  sensitive   = false

}


output "cloudflare_account_id" {
  value       = var.cloudflare_account_id
  description = "The Cloudflare account ID"
  sensitive   = false

}
output "vault_admin_password" {
  value       = var.vault_admin_password
  sensitive   = true
  description = "The admin password for Vault"
}

output "vault_admin_username" {
  value       = var.vault_admin_username
  sensitive   = false
  description = "The admin username for Vault"
}

output "rancher_bootstrap_password" {
  value       = length(var.rancher_bootstrap_password) > 0 ? var.rancher_bootstrap_password : random_password.rancher_bootstrap[0].result
  description = "The Rancher bootstrap password, either provided or generated."
  sensitive   = true
}
