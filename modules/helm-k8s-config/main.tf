resource "ssh_sensitive_resource" "kubeconfig" {
  # Note: moved from remote_file to ssh_sensitive_resource because
  # remote_file does not support bastion hosts and ssh_sensitive_resource does.
  # The default behaviour is to run file blocks and commands at create time
  # You can also specify 'destroy' to run the commands at destroy time
  when = "create"

  #   bastion_host        = var.kubeconfig_server_address
  #   bastion_port        = var.ssh_port
  #   bastion_user        = "root"
  #   bastion_private_key = var.ssh_private_key

  host        = var.kubeconfig_server_address
  port        = var.ssh_port
  user        = "root"
  private_key = var.ssh_private_key
  agent       = var.ssh_private_key == null

  # An ssh-agent with your SSH private keys should be running
  # Use 'private_key' to set the SSH key otherwise

  timeout = "15m"

  commands = [
    "cat /etc/rancher/rke2/rke2.yaml"
  ]

}

resource "local_sensitive_file" "kubeconfig" {
  count           = var.create_kubeconfig ? 1 : 0
  content         = local.kubeconfig_external
  filename        = "${var.cluster_name}_kubeconfig.yaml"
  file_permission = "600"
}
