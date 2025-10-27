output "control_plane_hosts" {
  description = "Map of control-plane name => ip."
  value       = local.control_plane_hosts
}

output "worker_hosts" {
  description = "Map of worker name => ip."
  value       = local.worker_hosts
}

output "all_hosts_by_name" {
  description = "Map of host name => { name, ip } across control-plane and workers (deduped by name)."
  value       = local.all_hosts_by_name
}

# Convenience: merged name=>ip for all nodes
output "all_hosts_name_to_ip" {
  description = "Merged map of all host name => ip (workers override on duplicate names)."
  value       = local.all_hosts_name_to_ip
}

# Convenience arrays (often useful for templatefile/for_each)
output "control_plane_names" {
  value       = [for s in var.control_plane_servers : s.name]
  description = "List of control-plane names."
}

output "control_plane_ips" {
  value       = [for s in var.control_plane_servers : s.ip]
  description = "List of control-plane IPs."
}

output "worker_names" {
  value       = [for s in var.worker_servers : s.name]
  description = "List of worker names."
}

output "worker_ips" {
  value       = [for s in var.worker_servers : s.ip]
  description = "List of worker IPs."
}

output "all_host_names" {
  value       = keys(local.all_hosts_by_name)
  description = "All host names (deduped)."
}

output "all_host_ips" {
  value       = [for s in values(local.all_hosts_by_name) : s.ip]
  description = "All host IPs aligned to all_host_names."
}


output "rke2_private_registries" {
  description = "Decoded registries.yaml content"
  value       = base64decode(local.rke2_registries_b64)
  sensitive   = true
}
