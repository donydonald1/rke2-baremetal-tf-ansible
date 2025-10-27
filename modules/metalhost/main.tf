resource "null_resource" "rhel_rh_enable" {
  # Only run on RHEL and iterate once per host
  for_each = var.is_rhel ? local.all_hosts_by_name : {}

  # Re-run if creds or SSH settings change
  triggers = {
    ip           = each.value.ip
    ssh_user     = var.ssh_user
    ssh_port     = var.ssh_port
    rhsm_user    = var.rhsm_username
    rhsm_pw_hash = sha256(var.rhsm_password) # don't store pw directly
  }

  connection {
    type        = "ssh"
    host        = each.value.ip
    user        = var.ssh_user
    port        = var.ssh_port
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "remote-exec" {
    inline = [
      # Register if needed; attach subs if already registered
      "sudo subscription-manager status >/dev/null 2>&1 || sudo subscription-manager register --username '${var.rhsm_username}' --password '${var.rhsm_password}' || true",
      "sudo subscription-manager attach --auto || true",

      # Yum/dnf hygiene + required services
      "sudo dnf clean all && sudo dnf makecache",
      "sudo systemctl enable --now rpcbind rpc-statd || true",

      # Reboot this host in background so SSH session can exit cleanly
      "nohup bash -c 'sleep 2; systemctl reboot || reboot' >/dev/null 2>&1 &",
    ]
  }

  # Wait for THIS host to return after reboot
  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      # Give the node a moment to go down
      sleep 10

      # Wait for SSH to become available on the same host
      until ssh ${local.ssh_args} -i ${var.ssh_private_key_file} -o ConnectTimeout=5 -p ${var.ssh_port} ${var.ssh_user}@${each.value.ip} true 2>/dev/null; do
        echo "Waiting for ${each.value.ip} to reboot and come back online..."
        sleep 15
      done
      echo "${each.value.ip} is back online."
    EOT
  }

  depends_on = [null_resource.nfs_host_mapping]
}


resource "null_resource" "write_rke2_registries" {
  for_each = { for s in var.control_plane_servers : s.name => s }

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
  # Iterate once per host (masters + workers)
  for_each = local.all_hosts_by_name

  # Re-run if these inputs change
  triggers = {
    ip               = each.value.ip
    ssh_user         = var.ssh_user
    ssh_port         = var.ssh_port
    nfs_server_ip    = var.nfs_server_ip
    nfs_shared_dir   = var.nfs_shared_dir
    nfs_mount_point  = var.nfs_mount_point
    nfsver           = var.nfsver
    private_key_hash = sha256(file(var.ssh_private_key_file))
  }

  connection {
    type        = "ssh"
    host        = each.value.ip
    user        = var.ssh_user
    port        = var.ssh_port
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "remote-exec" {
    inline = [
      <<-EOT
        set -euo pipefail

        MOUNT_SRC="${var.nfs_server_ip}:/var/nfs/shared/${var.nfs_shared_dir}"
        MOUNT_POINT="${var.nfs_mount_point}"

        # Consistent 'nfs' fstype; control version via nfsvers
        FSTYPE="nfs"
        COMMON_OPTS="defaults,_netdev,noatime,nofail,x-systemd.automount"
        OPTS="$${COMMON_OPTS},nfsvers=${var.nfsver},proto=tcp"
        FSTAB_LINE="$${MOUNT_SRC} $${MOUNT_POINT} $${FSTYPE} $${OPTS} 0 0"

        sudo mkdir -p "$${MOUNT_POINT}"

        # Idempotent /etc/fstab update for this mount
        if grep -Eq "^[^#]*[[:space:]]$${MOUNT_POINT}[[:space:]]+nfs" /etc/fstab; then
          sudo sed -i "s|^[^#]*[^[:space:]]\+[[:space:]]\+$${MOUNT_POINT}[[:space:]]\+nfs.*|$${FSTAB_LINE}|" /etc/fstab
        elif grep -Eq "^[^#]*$${MOUNT_SRC}[[:space:]]+$${MOUNT_POINT}[[:space:]]+nfs" /etc/fstab; then
          sudo sed -i "s|^[^#]*$${MOUNT_SRC}[[:space:]]\+$${MOUNT_POINT}[[:space:]]\+nfs.*|$${FSTAB_LINE}|" /etc/fstab
        else
          echo "$${FSTAB_LINE}" | sudo tee -a /etc/fstab >/dev/null
        fi

        sudo systemctl daemon-reload || true
        sudo mount -a -t nfs
      EOT
    ]
  }
  # depends_on = [null_resource.rhel_rh_enable]
}

