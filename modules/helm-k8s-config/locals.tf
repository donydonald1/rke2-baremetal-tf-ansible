locals {
  api_ip  = trimspace(var.manager_rke2_api_ip) != "" ? var.manager_rke2_api_ip : null
  api_dns = trimspace(var.manager_rke2_api_dns) != "" ? var.manager_rke2_api_dns : null

  kubeconfig_server_address = var.enable_rke2_cluster_api ? coalesce(local.api_ip, local.api_dns, var.kubeconfig_server_address) : var.manager_rke2_api_ip

  kubeconfig_external = replace(replace(ssh_sensitive_resource.kubeconfig.result, "127.0.0.1", local.kubeconfig_server_address), "default", var.cluster_name)
  kubeconfig_parsed   = yamldecode(local.kubeconfig_external)
  kubeconfig_data = {
    host                   = local.kubeconfig_parsed["clusters"][0]["cluster"]["server"]
    client_certificate     = base64decode(local.kubeconfig_parsed["users"][0]["user"]["client-certificate-data"])
    client_key             = base64decode(local.kubeconfig_parsed["users"][0]["user"]["client-key-data"])
    cluster_ca_certificate = base64decode(local.kubeconfig_parsed["clusters"][0]["cluster"]["certificate-authority-data"])
    cluster_name           = var.cluster_name
  }
}
