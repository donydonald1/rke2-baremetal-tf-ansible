####################NOTE -Rke2 config ####################

output "kubeconfig_client_key" {
  value       = local.kubeconfig_data.client_key
  description = "Client key for Kubernetes cluster authentication"
  sensitive   = true
  depends_on  = [ssh_sensitive_resource.kubeconfig]
}

output "kubeconfig_cluster_ca_certificate" {
  value       = local.kubeconfig_data.cluster_ca_certificate
  description = "CA certificate for the Kubernetes cluster"
  depends_on  = [ssh_sensitive_resource.kubeconfig]
}

output "kubeconfig_cluster_name" {
  value       = local.kubeconfig_data.cluster_name
  description = "Name of the Kubernetes cluster"
  depends_on  = [ssh_sensitive_resource.kubeconfig]
}

output "kubeconfig_host" {
  value       = local.kubeconfig_data.host
  description = "The Kubernetes cluster API server URL"
  depends_on  = [ssh_sensitive_resource.kubeconfig]
}

output "kubeconfig_client_certificate" {
  value       = local.kubeconfig_data.client_certificate
  description = "Client certificate for Kubernetes cluster authentication"
  sensitive   = true
  depends_on  = [ssh_sensitive_resource.kubeconfig]
}
output "kubeconfig_file" {
  value       = local.kubeconfig_external
  description = "Kubeconfig file content with external IP address"
  sensitive   = true
}
