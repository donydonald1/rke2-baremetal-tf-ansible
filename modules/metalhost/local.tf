locals {
  server_names    = [for s in var.baremetal_servers : s.name]
  server_ips      = [for s in var.baremetal_servers : s.ip]
  servers_by_name = { for s in var.baremetal_servers : s.name => s } # map lookup
  rke2_registries_yaml = var.private_registries != "" ? trimspace(var.private_registries) : yamlencode({
    configs = {
      (var.private_registry_url) = {
        auth = {
          username = var.private_registry_username
          password = var.private_registry_password
        }
        tls = {
          insecure_skip_verify = var.private_registry_insecure_skip_verify
        }
      }
      # "docker.io" = {
      #   auth = { username = var.dockerhub_registry_auth_username, password = var.dockerhub_registry_auth_password }
      # }
    }
    mirrors = {
      (var.private_registry_url) = {
        endpoint = ["http://${var.private_registry_url}"]
      }
      # "docker.io" = { endpoint = ["https://docker.io"] }
    }
  })
  rke2_registries_b64 = base64encode(local.rke2_registries_yaml)
  # shared flags for ssh to ignore host keys for all connections during provisioning.
  ssh_args = "-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -o PubkeyAuthentication=yes"
}

