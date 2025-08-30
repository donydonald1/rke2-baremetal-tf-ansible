output "vsphere_credential_name" {
  value = rancher2_cloud_credential.vsphere_credential_config.name

}

output "downstream_cluster_token" {
  value = rancher2_cluster.downstream_import.cluster_registration_token
  sensitive = true

}

output "downstream_cluster_manifest_url" {
  value = rancher2_cluster.downstream_import.cluster_registration_token[0].manifest_url

}

output "downstream_cluster_import_command" {
  value = rancher2_cluster.downstream_import.cluster_registration_token[0].insecure_command

}

output "downstream_cluster_id" {
  value = rancher2_cluster.downstream_import.id

}

output "downstream_cluster_name" {
  value = rancher2_cluster.downstream_import.name

}

