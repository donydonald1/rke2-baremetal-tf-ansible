data "remote_file" "kubeconfig" {
  conn {
    host        = module.manager.guest_ips[0]
    port        = var.ssh_port
    user        = "root"
    private_key = file(var.ssh_private_key)
    agent       = local.ssh_agent_identity

  }
  path = "/etc/rancher/rke2/rke2.yaml"
  # lifecycle {
  #   ignore_changes = [all]
  # }
  depends_on = [null_resource.kustomization, null_resource.run_ansible_playbook]
}

locals {
  kubeconfig_server_address = var.enable_rke2_cluster_api ? (var.manager_rke2_api_dns != "" ? var.manager_rke2_api_dns : module.manager.guest_ips[0]) : module.manager.guest_ips[0]
  kubeconfig_external       = replace(replace(data.remote_file.kubeconfig.content, "127.0.0.1", local.kubeconfig_server_address), "default", var.cluster_name)
  kubeconfig_parsed         = yamldecode(local.kubeconfig_external)
  kubeconfig_data = {
    host                   = local.kubeconfig_parsed["clusters"][0]["cluster"]["server"]
    client_certificate     = base64decode(local.kubeconfig_parsed["users"][0]["user"]["client-certificate-data"])
    client_key             = base64decode(local.kubeconfig_parsed["users"][0]["user"]["client-key-data"])
    cluster_ca_certificate = base64decode(local.kubeconfig_parsed["clusters"][0]["cluster"]["certificate-authority-data"])
    cluster_name           = var.cluster_name
  }
}

resource "local_sensitive_file" "kubeconfig" {
  count           = var.create_kubeconfig ? 1 : 0
  content         = local.kubeconfig_external
  filename        = "${var.cluster_name}_kubeconfig.yaml"
  file_permission = "600"
}

resource "time_sleep" "wait_for_kubeconfig" {
  depends_on      = [data.remote_file.kubeconfig, local_sensitive_file.kubeconfig]
  create_duration = var.wait != null ? var.wait : "1s"
}
