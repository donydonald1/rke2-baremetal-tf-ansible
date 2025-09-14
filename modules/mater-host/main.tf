resource "null_resource" "rhel_rh_enable" {
  for_each = var.is_rhel ? {
    for s in var.baremetal_servers : s.name => s
  } : {}

  connection {
    type        = "ssh"
    host        = each.value.ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo subscription-manager register --username '${var.rhsm_username}' --password '${var.rhsm_password}' || true",
      "sudo dnf clean all && sudo dnf makecache",
      "sudo dnf install -y nfs-utils",
    ]
  }
}

resource "null_resource" "write_rke2_registries" {
  for_each = { for s in var.baremetal_servers : s.name => s }

  connection {
    type        = "ssh"
    host        = each.value.ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/rancher/rke2",
      "echo '${local.rke2_registries_b64}' | base64 -d | sudo tee /etc/rancher/rke2/registries.yaml >/dev/null",
      "sudo chown root:root /etc/rancher/rke2/registries.yaml",
      "sudo chmod 0644 /etc/rancher/rke2/registries.yaml",
    ]
  }
}
