output "manager_vm_names" {
  description = "The names of the created virtual machines."
  value       = module.manager.vm_names

}

output "manager_guest_ips" {
  description = "The guest IPs of the created virtual machines."
  value       = module.manager.guest_ips

}

output "manager_ips" {
  description = "The configured IPs for the virtual machines."
  value       = module.manager.configured_ips

}


####################NOTE -Rke2 config ####################

output "kubeconfig_client_key" {
  value       = local.kubeconfig_data.client_key
  description = "Client key for Kubernetes cluster authentication"
  sensitive   = true
  depends_on  = [null_resource.kustomization]
}

output "kubeconfig_cluster_ca_certificate" {
  value       = local.kubeconfig_data.cluster_ca_certificate
  description = "CA certificate for the Kubernetes cluster"
  depends_on  = [null_resource.kustomization]
}

output "kubeconfig_cluster_name" {
  value       = local.kubeconfig_data.cluster_name
  description = "Name of the Kubernetes cluster"
  depends_on  = [null_resource.kustomization]
}

output "kubeconfig_host" {
  value       = local.kubeconfig_data.host
  description = "The Kubernetes cluster API server URL"
  depends_on  = [null_resource.kustomization]
}

output "kubeconfig_client_certificate" {
  value       = local.kubeconfig_data.client_certificate
  description = "Client certificate for Kubernetes cluster authentication"
  sensitive   = true
  depends_on  = [null_resource.kustomization]
}
output "kubeconfig_file" {
  value       = local.kubeconfig_external
  description = "Kubeconfig file content with external IP address"
  sensitive   = true
}

output "rancher_bootstrap_password" {
  value       = length(var.rancher_bootstrap_password) > 0 ? var.rancher_bootstrap_password : random_password.rancher_bootstrap[0].result
  description = "The Rancher bootstrap password, either provided or generated."
  sensitive   = true
}

output "vault_admin_password" {
  value       = var.vault_admin_password
  sensitive   = true
  description = "The admin password for Vault"
}

output "vault_admin_username" {
  value       = var.vault_admin_username
  description = "The admin username for Vault"
}

output "vault_hostname" {
  value       = var.vault_hostname
  description = "The hostname for Vault"

}
