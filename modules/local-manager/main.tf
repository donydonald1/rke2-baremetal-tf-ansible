




# resource "null_resource" "run_ansible_playbook" {
#   depends_on = [
#     local_file.ansible_rke2_playbook,
#     local_file.ansible_inventory,
#     null_resource.install_ansible_role,
#     null_resource.control_plane_config
#   ]

#   provisioner "local-exec" {
#     environment = {
#       ANSIBLE_FORCE_COLOR = "1"
#       PY_COLORS           = "1"
#       TERM                = "xterm-256color"
#     }

#     command = <<EOT
#       ansible-playbook -i ${path.module}/${var.cluster_name}-inventory.ini ${path.module}/${var.cluster_name}-deploy-rke2.yml
#     EOT
#   }

#   triggers = {
#     cluster_config_hash = md5(local.cluster_config_values)
#   }
# }


# # This is where all the setup of Kubernetes components happen
# resource "null_resource" "kustomization" {
#   triggers = {
#     # Redeploy helm charts when the underlying values change
#     helm_values_yaml = join("---\n", [
#       local.vault_values,
#       local.cert_manager_values,
#       local.rancher_values,
#       local.argocd_values,
#       # local.metallb_values,
#       local.external_dns_values,
#       # local.cloudflared_values,
#       local.external_dns_values
#     ])
#     # Redeploy when versions of addons need to be updated
#     versions = join("\n", [
#       coalesce(var.initial_rke2_channel, "N/A"),
#       coalesce(var.rke2_version, "N/A"),
#     ])
#   }

#   connection {
#     user           = "root"
#     private_key    = file(var.ssh_private_key)
#     agent_identity = local.ssh_agent_identity
#     host           = module.manager.guest_ips[0]
#     port           = var.ssh_port
#     script_path    = "/root/terraform_%RAND%.sh"
#   }

#   # Upload kustomization.yaml, containing Hetzner CSI & CSM, as well as kured.
#   provisioner "file" {
#     content     = local.kustomization_backup_yaml
#     destination = "/var/post_install/kustomization.yaml"
#   }
#   # Upload the system upgrade controller plans config
#   provisioner "file" {
#     content = templatefile(
#       "${path.module}/templates/plans.yaml.tpl",
#       {
#         channel          = var.initial_rke2_channel
#         version          = var.rke2_version
#         disable_eviction = !var.system_upgrade_enable_eviction
#         drain            = var.system_upgrade_use_drain
#     })
#     destination = "/var/post_install/plans.yaml"
#   }


#   # Upload the cert-manager config
#   provisioner "file" {
#     content = templatefile(
#       "${path.module}/templates/cert_manager.yaml.tpl",
#       {
#         version   = var.cert_manager_version
#         bootstrap = var.cert_manager_helmchart_bootstrap
#         values    = indent(4, trimspace(local.cert_manager_values))
#     })
#     destination = "/var/post_install/cert_manager.yaml"
#   }
#   # Upload the Rancher config
#   provisioner "file" {
#     content = templatefile(
#       "${path.module}/templates/rancher.yaml.tpl",
#       {
#         rancher_install_channel = var.rancher_install_channel
#         version                 = var.rancher_version
#         bootstrap               = var.rancher_helmchart_bootstrap
#         values                  = indent(4, trimspace(local.rancher_values))
#     })
#     destination = "/var/post_install/rancher.yaml"
#   }
#   # argocd setup
#   provisioner "file" {
#     content = templatefile(
#       "${path.module}/templates/argocd-values.yaml.tpl",
#       {
#         values = indent(4, trimspace(local.argocd_values))
#         # bootstrap = var.argocd_helmchart_bootstrap
#         vault_addr = base64encode("http://vault.vault.svc.cluster.local:8200")
#     })
#     destination = "/var/post_install/argocd.yaml"
#   }

#   # cloudflared setup
#   # provisioner "file" {
#   #   content = templatefile(
#   #     "${path.module}/templates/cloudflared.yaml.tpl",
#   #     {
#   #       values = local.cloudflared_values
#   #   })
#   #   destination = "/var/post_install/cloudflared.yaml"
#   # }
#   # external-dns setup
#   provisioner "file" {
#     content = templatefile(
#       "${path.module}/templates/external-dns.yaml.tpl",
#       {
#         values = indent(4, trimspace(local.external_dns_values))
#     })
#     destination = "/var/post_install/external-dns.yaml"
#   }
#   # external_secret setup
#   provisioner "file" {
#     content = templatefile(
#       "${path.module}/templates/external-secret.yaml.tpl",
#       {
#         values = indent(4, trimspace(local.external_secrets_values))
#     })
#     destination = "/var/post_install/external-secrets.yaml"
#   }
#   # vault setup
#   provisioner "file" {
#     content = templatefile(
#       "${path.module}/templates/vault.yaml.tpl",
#       {
#         values               = indent(4, trimspace(local.vault_values))
#         domain               = var.domain
#         username             = var.vault_admin_username
#         vault_admin_password = var.vault_admin_password
#     })
#     destination = "/var/post_install/vault.yaml"
#   }
#   # metallb setup
#   # provisioner "file" {
#   #   content = templatefile(
#   #     "${path.module}/templates/metallb.yaml.tpl",
#   #     {
#   #       values = indent(4, trimspace(local.metallb_values))
#   #   })
#   #   destination = "/var/post_install/metallb.yaml"
#   # }
#   # Deploy our post-installation kustomization
#   provisioner "remote-exec" {
#     inline = concat([
#       "set -ex",
#       "export PATH=$PATH:/opt/rke2/bin",
#       "echo export PATH=/var/lib/rancher/rke2/bin:$PATH >> ~/.bashrc",
#       "echo export KUBECONFIG=/etc/rancher/rke2/rke2.yaml  >> $HOME/.bashrc",
#       "source ~/.bashrc",
#       "export KUBECONFIG=/etc/rancher/rke2/rke2.yaml",
#       # This ugly hack is here, because terraform serializes the
#       # embedded yaml files with "- |2", when there is more than
#       # one yamldocument in the embedded file. Kustomize does not understand
#       # that syntax and tries to parse the blocks content as a file, resulting
#       # in weird errors. so gnu sed with funny escaping is used to
#       # replace lines like "- |3" by "- |" (yaml block syntax).
#       # due to indendation this should not changes the embedded
#       # manifests themselves
#       "sed -i 's/^- |[0-9]\\+$/- |/g' /var/post_install/kustomization.yaml",

#       # Wait for rke2 to become ready (we check one more time) because in some edge cases,
#       # the cluster had become unvailable for a few seconds, at this very instant.
#       <<-EOT
#       timeout 360 bash <<EOF
#         until [[ "\$(kubectl get --raw='/readyz' 2> /dev/null)" == "ok" ]]; do
#           echo "Waiting for the cluster to become ready..."
#           sleep 2
#         done
#       EOF
#       EOT
#       ]
#       ,

#       [
#         # Ready, set, go for the kustomization
#         "kubectl apply -k /var/post_install",
#         "echo 'Waiting for the system-upgrade-controller deployment to become available...'",
#         "kubectl -n system-upgrade wait --for=condition=available --timeout=360s deployment/system-upgrade-controller",
#         "sleep 7", # important as the system upgrade controller CRDs sometimes don't get ready right away, especially with Cilium.
#         "kubectl -n system-upgrade apply -f /var/post_install/plans.yaml"
#     ])
#   }

#   depends_on = [
#     null_resource.run_ansible_playbook
#   ]
# }

# resource "time_sleep" "sleep-wait-vault" {
#   depends_on      = [null_resource.kustomization]
#   create_duration = var.vault_wait_time != null ? var.vault_wait_time : "1s"
# }
