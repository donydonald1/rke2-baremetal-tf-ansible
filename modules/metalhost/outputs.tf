output "server_names" {
  value = local.server_names
}

output "server_ips" {
  value = local.server_ips
}

output "servers_by_name" {
  value = local.servers_by_name
}

output "rke2_private_registries" {
  description = "Decoded registries.yaml content"
  value       = base64decode(local.rke2_registries_b64)
  sensitive   = true
}
