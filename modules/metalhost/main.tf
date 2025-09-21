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
      "sudo systemctl enable --now rpcbind rpc-statd"
    ]
  }

  provisioner "local-exec" {
    command = <<-EOT
      ssh ${local.ssh_args} -i ${var.ssh_private_key_file} -o ConnectTimeout=2 -p ${var.ssh_port} ${var.ssh_user}@${var.baremetal_servers[0].ip} '(sleep 5; reboot)&'; sleep 10
      until ssh ${local.ssh_args} -i ${var.ssh_private_key_file} -o ConnectTimeout=2 -p ${var.ssh_port} ${var.ssh_user}@${var.baremetal_servers[0].ip} true 2> /dev/null
      do
        echo "Waiting for OS to reboot and become available..."
        sleep 30
      done
    EOT
  }
  depends_on = [null_resource.nfs_host_mapping]
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
  depends_on = [null_resource.rhel_rh_enable]
}

resource "null_resource" "nfs_host_mapping" {
  for_each = { for s in var.baremetal_servers : s.name => s }

  connection {
    type        = "ssh"
    host        = each.value.ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
        set -euo pipefail

        MOUNT_SRC="${var.nfs_server_ip}:/var/nfs/shared/${var.nfs_shared_dir}"
        MOUNT_POINT="${var.nfs_mount_point}"

        # Use type 'nfs' for both, and pin version via nfsvers=
        FSTYPE="nfs"
        COMMON_OPTS="defaults,_netdev,noatime,nofail,x-systemd.automount"
        OPTS="$${COMMON_OPTS},nfsvers=${var.nfsver},proto=tcp"
        FSTAB_LINE="$${MOUNT_SRC} $${MOUNT_POINT} $${FSTYPE} $${OPTS} 0 0"

        # Prep mount point
        sudo mkdir -p "$${MOUNT_POINT}"

        # Add or update /etc/fstab entry idempotently
        if grep -Eq "^[^#]*[[:space:]]$${MOUNT_POINT}[[:space:]]+nfs" /etc/fstab; then
          # Replace any existing line for this mount point
          sudo sed -i "s|^[^#]*[^[:space:]]\+[[:space:]]\+$${MOUNT_POINT}[[:space:]]\+nfs.*|$${FSTAB_LINE}|" /etc/fstab
        elif grep -Eq "^[^#]*$${MOUNT_SRC}[[:space:]]+$${MOUNT_POINT}[[:space:]]+nfs" /etc/fstab; then
          sudo sed -i "s|^[^#]*$${MOUNT_SRC}[[:space:]]\+$${MOUNT_POINT}[[:space:]]\+nfs.*|$${FSTAB_LINE}|" /etc/fstab
        else
          echo "$${FSTAB_LINE}" | sudo tee -a /etc/fstab >/dev/null
        fi

        # Reload systemd units (automount) and mount now
        sudo systemctl daemon-reload || true
        sudo mount -a -t nfs
      EOT
    ]
  }
}

