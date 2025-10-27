module "rke2_metalhost_servers" {
  source                                = "./modules/metalhost/"
  control_plane_servers                 = var.control_plane_servers
  worker_servers                        = var.worker_servers
  private_registry_url                  = var.private_registry_url
  private_registry_username             = var.private_registry_username
  private_registry_password             = var.private_registry_password
  private_registry_insecure_skip_verify = var.private_registry_insecure_skip_verify
  dockerhub_registry_auth_username      = var.dockerhub_registry_auth_username
  dockerhub_registry_auth_password      = var.dockerhub_registry_auth_password
  ssh_user                              = var.ssh_user
  is_rhel                               = var.is_rhel
  rhsm_username                         = var.rhsm_username
  rhsm_password                         = var.rhsm_password
  ssh_private_key_file                  = var.ssh_private_key_file
  nfs_server_ip                         = var.nfs_server_ip
  nfs_shared_dir                        = var.nfs_shared_dir
  nfsver                                = var.nfsver
  nfs_mount_point                       = var.nfs_mount_point
}

resource "null_resource" "control_plane_config" {
  for_each = { for idx, ip in module.rke2_metalhost_servers.control_plane_hosts : idx => ip }

  connection {
    user        = "root"
    private_key = file(var.ssh_private_key_file)

    host        = each.value
    port        = var.ssh_port
    script_path = "/root/terraform_%RAND%.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/rancher/rke2 /var/lib/rancher/rke2/ /var/post_install /opt/rke2-artifacts/ /var/lib/rancher/rke2/server/manifests/",
      "export PATH=$PATH:/opt/rke2/bin",
      "echo export PATH=/var/lib/rancher/rke2/bin:$PATH >> ~/.bashrc",
      "echo export KUBECONFIG=/etc/rancher/rke2/rke2.yaml  >> $HOME/.bashrc",
    ]
  }

  provisioner "file" {
    content     = file("${path.module}/templates/rke2-pss.yaml.tpl")
    destination = "/etc/rancher/rke2/rke2-psa.yaml"
  }

  provisioner "file" {
    content     = file("${path.module}/templates/audit-policy.yaml.tpl")
    destination = "/etc/rancher/rke2/audit-policy.yaml"
  }
}

resource "random_password" "rke2_token" {
  length  = 32
  special = false
}

resource "random_password" "rancher_bootstrap" {
  # count   = length(var.rancher_bootstrap_password) == 0 ? 1 : 0
  length  = 48
  special = false
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/ansible_inventory.tftpl", {
    control_plane_hosts = module.rke2_metalhost_servers.control_plane_hosts
    worker_hosts        = module.rke2_metalhost_servers.worker_hosts
    vm_user             = "root"
    ssh_port            = var.ssh_port
    ssh_private_key     = var.ssh_private_key_file
    cluster_name        = var.cluster_name
  })
  filename   = "${path.root}/${var.cluster_name}-inventory.ini"
  depends_on = [module.rke2_metalhost_servers]
}

resource "local_file" "ansible_rke2_playbook" {
  content = templatefile("${path.module}/templates/rke2_playbook.tftpl", {
    ansible_hosts_group   = local.ansible_hosts_group
    cluster_config_values = local.cluster_config_values
  })
  filename = "${path.root}/${var.cluster_name}-deploy-rke2.yml"
}

resource "null_resource" "install_ansible_role" {
  provisioner "local-exec" {
    command = <<EOT
      # if ansible-galaxy list | grep -q 'lablabs.rke2'; then
      #   ansible-galaxy remove lablabs.rke2
      # fi
      ansible-galaxy role install lablabs.rke2
    EOT
  }

  triggers = {
    cluster_config_hash = md5(local.cluster_config_values)
  }
}

resource "null_resource" "run_ansible_playbook" {
  depends_on = [
    local_file.ansible_rke2_playbook,
    local_file.ansible_inventory,
    null_resource.install_ansible_role,
    null_resource.control_plane_config,
    # null_resource.uninstall_rke2
  ]

  provisioner "local-exec" {
    environment = {
      ANSIBLE_FORCE_COLOR = "1"
      PY_COLORS           = "1"
      TERM                = "xterm-256color"
    }

    command = <<EOT
      ansible-playbook -i ${path.root}/${var.cluster_name}-inventory.ini ${path.root}/${var.cluster_name}-deploy-rke2.yml
    EOT
  }

  triggers = {
    cluster_config_hash = md5(local.cluster_config_values)
  }
}

resource "null_resource" "rke2_selinux_labels" {
  for_each = toset(module.rke2_metalhost_servers.server_ips)

  connection {
    type        = "ssh"
    host        = each.value
    user        = "root"
    private_key = file(var.ssh_private_key_file)
  }

  triggers = {
    host       = each.value
    script_rev = "2"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo dnf -y install policycoreutils-python-utils || sudo yum -y install policycoreutils-python-utils || true",
      "sudo bash -lc \"find /var/lib/rancher/rke2 -type f \\( -path '*/bin/containerd' -o -path '*/bin/runc' \\) -print || true\"",
      "sudo bash -lc 'if semanage fcontext -l | awk \"{print \\$1,\\$3}\" | grep -E \"^/var/lib/rancher/rke2/.*/bin/containerd .*\" >/dev/null; then semanage fcontext -m -t container_runtime_exec_t \"/var/lib/rancher/rke2/.*/bin/containerd\"; else semanage fcontext -a -t container_runtime_exec_t \"/var/lib/rancher/rke2/.*/bin/containerd\"; fi'",
      "sudo bash -lc 'if semanage fcontext -l | awk \"{print \\$1,\\$3}\" | grep -E \"^/var/lib/rancher/rke2/.*/bin/runc .*\" >/dev/null; then semanage fcontext -m -t container_runtime_exec_t \"/var/lib/rancher/rke2/.*/bin/runc\"; else semanage fcontext -a -t container_runtime_exec_t \"/var/lib/rancher/rke2/.*/bin/runc\"; fi'",
      "sudo bash -lc 'if semanage fcontext -l | awk \"{print \\$1,\\$3}\" | grep -E \"^/usr/local/bin/rke2 .*\" >/dev/null; then semanage fcontext -m -t container_runtime_exec_t \"/usr/local/bin/rke2\"; else semanage fcontext -a -t container_runtime_exec_t \"/usr/local/bin/rke2\"; fi'",
      "sudo restorecon -RFv /var/lib/rancher/rke2 /usr/local/bin || true",
    ]
  }

  depends_on = [local_file.ansible_rke2_playbook]
}




# This is where all the setup of Kubernetes components happen
resource "null_resource" "kustomization" {
  triggers = {
    # Redeploy helm charts when the underlying values change
    helm_values_yaml = join("---\n", [
      local.vault_values,
      local.cert_manager_values,
      local.longhorn_values,
      local.rancher_values,
      local.argocd_values,
      local.external_dns_values,
      local.csi-driver-nfs_values,
      local.csi_driver_nfs_localpath_values,
      # local.cloudflared_values,
      local.external_dns_values
    ])
    # Redeploy when versions of addons need to be updated
    versions = join("\n", [
      coalesce(var.initial_rke2_channel, "N/A"),
      coalesce(var.rke2_version, "N/A"),
      coalesce(var.longhorn_version, "N/A"),
    ])
  }

  connection {
    user        = "root"
    private_key = file(var.ssh_private_key_file)
    host        = module.rke2_metalhost_servers.server_ips[0]
    port        = var.ssh_port
    script_path = "/root/terraform_%RAND%.sh"
  }

  # Upload kustomization.yaml, containing Hetzner CSI & CSM, as well as kured.
  provisioner "file" {
    content     = local.kustomization_backup_yaml
    destination = "/var/post_install/kustomization.yaml"
  }
  # Upload the system upgrade controller plans config
  provisioner "file" {
    content = templatefile(
      "${path.module}/templates/plans.yaml.tpl",
      {
        channel          = var.initial_rke2_channel
        version          = var.rke2_version
        disable_eviction = !var.system_upgrade_enable_eviction
        drain            = var.system_upgrade_use_drain
    })
    destination = "/var/post_install/plans.yaml"
  }

  # Upload the Longhorn config
  provisioner "file" {
    content = templatefile(
      "${path.module}/templates/longhorn.yaml.tpl",
      {
        longhorn_namespace  = var.longhorn_namespace
        longhorn_repository = var.longhorn_repository
        version             = var.longhorn_version
        bootstrap           = var.longhorn_helmchart_bootstrap
        values              = indent(4, chomp(local.longhorn_values))
    })
    destination = "/var/post_install/longhorn.yaml"
  }

  # Upload the cert-manager config
  provisioner "file" {
    content = templatefile(
      "${path.module}/templates/cert_manager.yaml.tpl",
      {
        version   = var.cert_manager_version
        bootstrap = var.cert_manager_helmchart_bootstrap
        values    = indent(4, trimspace(local.cert_manager_values))
    })
    destination = "/var/post_install/cert_manager.yaml"
  }
  # Upload the Rancher config
  provisioner "file" {
    content = templatefile(
      "${path.module}/templates/rancher.yaml.tpl",
      {
        rancher_install_channel = var.rancher_install_channel
        version                 = var.rancher_version
        bootstrap               = var.rancher_helmchart_bootstrap
        values                  = indent(4, trimspace(local.rancher_values))
    })
    destination = "/var/post_install/rancher.yaml"
  }
  # Upload the CSI Driver NFS config
  provisioner "file" {
    content = templatefile(
      "${path.module}/templates/csi-driver-nfs.yaml.tpl",
      {
        values = indent(4, trimspace(local.csi-driver-nfs_values))
    })
    destination = "/var/post_install/csi-driver-nfs.yaml"
  }

  # Upload the CSI Driver NFS LocalPath config
  provisioner "file" {
    content = templatefile(
      "${path.module}/templates/csi-driver-nfs-localpath.yaml.tpl",
      {
        values = indent(4, trimspace(local.csi_driver_nfs_localpath_values))
    })
    destination = "/var/post_install/csi-driver-nfs-localpath.yaml"
  }
  # argocd setup
  provisioner "file" {
    content = templatefile(
      "${path.module}/templates/argocd-values.yaml.tpl",
      {
        values = indent(4, trimspace(local.argocd_values))
        # bootstrap = var.argocd_helmchart_bootstrap
        # vault_addr      = base64encode("http://vault.vault.svc.cluster.local:8200")
        # vault_token     = base64encode(var.vault_admin_password)
        # vault_auth_type = base64encode("token")
        # avp_type        = base64encode("vault")
    })
    destination = "/var/post_install/argocd.yaml"
  }

  # external-dns setup
  provisioner "file" {
    content = templatefile(
      "${path.module}/templates/external-dns.yaml.tpl",
      {
        values = indent(4, trimspace(local.external_dns_values))
    })
    destination = "/var/post_install/external-dns.yaml"
  }
  # external_secret setup
  provisioner "file" {
    content = templatefile(
      "${path.module}/templates/external-secret.yaml.tpl",
      {
        values = indent(4, trimspace(local.external_secrets_values))
    })
    destination = "/var/post_install/external-secrets.yaml"
  }
  # vault setup
  provisioner "file" {
    content = templatefile(
      "${path.module}/templates/vault.yaml.tpl",
      {
        vault = local.vault_values
        # vault_base_domain    = var.domain
        # username             = var.vault_admin_username
        # vault_admin_password = var.vault_admin_password
    })
    destination = "/var/post_install/vault.yaml"
  }

  # Deploy our post-installation kustomization
  provisioner "remote-exec" {
    inline = concat([
      "set -ex",
      "export PATH=$PATH:/opt/rke2/bin",
      "echo export PATH=/var/lib/rancher/rke2/bin:$PATH >> ~/.bashrc",
      "echo export KUBECONFIG=/etc/rancher/rke2/rke2.yaml  >> $HOME/.bashrc",
      "source ~/.bashrc",
      "export KUBECONFIG=/etc/rancher/rke2/rke2.yaml",
      # This ugly hack is here, because terraform serializes the
      # embedded yaml files with "- |2", when there is more than
      # one yamldocument in the embedded file. Kustomize does not understand
      # that syntax and tries to parse the blocks content as a file, resulting
      # in weird errors. so gnu sed with funny escaping is used to
      # replace lines like "- |3" by "- |" (yaml block syntax).
      # due to indendation this should not changes the embedded
      # manifests themselves
      "sed -i 's/^- |[0-9]\\+$/- |/g' /var/post_install/kustomization.yaml",

      # Wait for rke2 to become ready (we check one more time) because in some edge cases,
      # the cluster had become unvailable for a few seconds, at this very instant.
      <<-EOT
      timeout 360 bash <<EOF
        until [[ "\$(kubectl get --raw='/readyz' 2> /dev/null)" == "ok" ]]; do
          echo "Waiting for the cluster to become ready..."
          sleep 2
        done
      EOF
      EOT
      ]
      ,

      [
        # Ready, set, go for the kustomization
        "kubectl apply -k /var/post_install",
        "echo 'Waiting for the system-upgrade-controller deployment to become available...'",
        "kubectl -n system-upgrade wait --for=condition=available --timeout=360s deployment/system-upgrade-controller",
        "sleep 7", # important as the system upgrade controller CRDs sometimes don't get ready right away, especially with Cilium.
        "kubectl -n system-upgrade apply -f /var/post_install/plans.yaml"
    ])
  }

  depends_on = [
    null_resource.run_ansible_playbook,
    # module.kubeconfig,
    null_resource.rke2_selinux_labels,
  ]
}

# resource "null_resource" "uninstall_rke2" {
#   # (typo fix) master, not mater
#   for_each = { for idx, ip in module.rke2_metalhost_servers.server_ips : idx => ip }

#   # Store all external refs ON the resource so we can use self.triggers.* at destroy-time
#   triggers = {
#     host            = each.value
#     ssh_port        = var.ssh_port
#     ssh_user        = "root"
#     ssh_private_key = file(var.ssh_private_key_file)
#   }

#   connection {
#     type        = "ssh"
#     user        = self.triggers.ssh_user
#     host        = self.triggers.host
#     port        = tonumber(self.triggers.ssh_port)
#     private_key = self.triggers.ssh_private_key
#     script_path = "/root/terraform_%RAND%.sh"
#   }

#   provisioner "remote-exec" {
#     when       = destroy
#     on_failure = continue

#     inline = [
#       "set -euxo pipefail",
#       "if [ -x /usr/bin/rke2-uninstall.sh ]; then",
#       "  sudo /usr/bin/rke2-uninstall.sh",
#       "elif [ -x /usr/local/bin/rke2-uninstall.sh ]; then",
#       "  sudo /usr/local/bin/rke2-uninstall.sh",
#       "else",
#       "  sudo systemctl stop rke2-server || true",
#       "  sudo systemctl disable rke2-server || true",
#       "fi",
#       "sudo rm -rf /etc/rancher/rke2 /var/lib/rancher/rke2 /var/post_install /opt/rke2-artifacts /var/lib/rancher/rke2/server/manifests || true",
#     ]
#   }
#   depends_on = [
#     module.rke2_metalhost_servers,
#     null_resource.run_ansible_playbook,
#     helm_release.cloudflared,
#     helm_release.vault_operator,
#     kubernetes_namespace.this,
#     kubectl_manifest.vault_role,
#     kubectl_manifest.vault_clusterrolebinding,
#     kubectl_manifest.vault_sa,
#     kubectl_manifest.vault_rolebinding,
#     kubectl_manifest.vault,
#     helm_release.cloudflared,
#     kubernetes_secret.cert_manager_token,
#     kubernetes_secret.cloudflared_credentials,
#     kubernetes_secret.external_dns_token,
#     kubernetes_secret.vault_credentials,
#     kubernetes_namespace.this,
#     kubectl_manifest.clusterissuer_letsencrypt_prod,
#     kubectl_manifest.external_secret_vault,
#     kubectl_manifest.app_projects,
#     kubernetes_config_map.cmp-plugin

#   ]
#   # depends_on = [module.rke2_metalhost_servers]
# }
