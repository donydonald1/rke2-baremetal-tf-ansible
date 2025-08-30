locals {
cloudinit_write_files_common = <<EOT
# Create a script to resize the disk
- path: /usr/local/bin/disk_resize.sh
  permissions: '0755'
  content: |
    #!/bin/bash
    VG_NAME="sysvg"
    LV_NAME="lv_var"
    DISK="/dev/sdb"
    MOUNT_POINT="/var"

    # Unmount partition if mounted
    if mount | grep -q "$${DISK}1"; then
        echo "Unmounting $${DISK}1..."
        umount "$${DISK}1" || { echo "Failed to unmount $${DISK}1. Exiting."; exit 1; }
    else
        echo "$${DISK}1 is not mounted. Proceeding..."
    fi

    # Clear all partitions and metadata
    echo "Clearing all partitions and metadata on $DISK..."
    sgdisk --zap-all $DISK || { echo "Failed to clear partitions on $DISK. Exiting."; exit 1; }
    wipefs -a $DISK || { echo "Failed to wipe $DISK. Exiting."; exit 1; }

    # Create a physical volume
    echo "Creating physical volume on $DISK..."
    pvcreate $DISK || { echo "Failed to create physical volume on $DISK. Exiting."; exit 1; }

    # Add the disk to the volume group
    echo "Adding $DISK to volume group $VG_NAME..."
    vgextend $VG_NAME $DISK || { echo "Failed to extend volume group $VG_NAME. Exiting."; exit 1; }

    # Extend the logical volume
    echo "Extending logical volume $LV_NAME..."
    lvextend -l +100%FREE /dev/$VG_NAME/$LV_NAME || { echo "Failed to extend logical volume $LV_NAME. Exiting."; exit 1; }

    # Resize the filesystem
    echo "Resizing filesystem on $LV_NAME..."
    xfs_growfs /dev/mapper/$VG_NAME-$LV_NAME || { echo "Failed to resize filesystem. Exiting."; exit 1; }

    # Verify the resize
    echo "Verifying resized filesystem..."
    df -h $MOUNT_POINT

    echo "Resize operation completed successfully."
# Disable ssh password authentication
- content: |
    Port 22
    PasswordAuthentication no
    X11Forwarding no
    MaxAuthTries 3
    AllowTcpForwarding no
    AllowAgentForwarding no
    AuthorizedKeysFile .ssh/authorized_keys
  path: /etc/ssh/sshd_config.d/kube-hetzner.conf

# Create NetworkManager configuration for unmanaged devices
- path: /etc/NetworkManager/conf.d/rke2-canal.conf
  content: |
    [keyfile]
    unmanaged-devices=interface-name:cali*;interface-name:flannel*
  permissions: "0644"
- path: /etc/sysctl.conf
  content: |
    vm.swappiness=0
    vm.panic_on_oom=0
    vm.overcommit_memory=1
    kernel.panic=10
    kernel.panic_on_oops=1
    vm.max_map_count=262144
    net.ipv4.ip_local_port_range=1024 65000
    net.core.somaxconn=10000
    net.ipv4.tcp_tw_reuse=1
    net.ipv4.tcp_fin_timeout=15
    net.core.somaxconn=4096
    net.core.netdev_max_backlog=4096
    net.core.rmem_max=16777216
    net.core.wmem_max=16777216
    net.ipv4.tcp_max_syn_backlog=20480
    net.ipv4.tcp_max_tw_buckets=400000
    net.ipv4.tcp_no_metrics_save=1
    net.ipv4.tcp_rmem=4096 87380 16777216
    net.ipv4.tcp_syn_retries=2
    net.ipv4.tcp_synack_retries=2
    net.ipv4.tcp_wmem=4096 65536 16777216
    net.ipv4.neigh.default.gc_thresh1=8096
    net.ipv4.neigh.default.gc_thresh2=12288
    net.ipv4.neigh.default.gc_thresh3=16384
    net.ipv4.tcp_keepalive_time=600
    net.ipv4.ip_forward=1
    net.ipv6.conf.all.disable_ipv6=1
    net.ipv6.conf.default.disable_ipv6=1
    fs.inotify.max_user_instances=8192
    fs.inotify.max_user_watches=1048576
  EOT

cloudinit_runcmd_common = <<EOT

  # SELinux permission for the SSH alternative port.
  - [semanage, port, '-a', '-t', ssh_port_t, '-p', tcp, '22']

  # Update and upgrade the RHEL OS
  - [yum, '-y', 'update']
  - [yum, '-y', 'upgrade']
  # Bounds the amount of logs that can survive on the system
  - [sed, '-i', 's/#SystemMaxUse=/SystemMaxUse=3G/g', /etc/systemd/journald.conf]
  - [sed, '-i', 's/#MaxRetentionSec=/MaxRetentionSec=1week/g', /etc/systemd/journald.conf]

  # Restart the sshd service to apply the new config
  - [systemctl, 'restart', 'sshd']
  # Cleanup some logs
  - [truncate, '-s', '0', '/var/log/audit/audit.log']

EOT
}