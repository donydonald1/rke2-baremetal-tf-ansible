module "kubeconfig" {
  source                    = "./modules/helm-k8s-config/"
  create_kubeconfig         = var.create_kubeconfig
  cluster_name              = var.cluster_name
  kubeconfig_server_address = var.baremetal_servers[0].ip
  enable_rke2_cluster_api   = var.enable_rke2_cluster_api
  manager_rke2_api_dns      = var.manager_rke2_api_dns
  ssh_private_key           = file(var.ssh_private_key_file)
  ssh_port                  = var.ssh_port
  manager_rke2_api_ip       = var.manager_rke2_api_ip
  depends_on                = [null_resource.run_ansible_playbook, null_resource.rke2_selinux_labels]
}
