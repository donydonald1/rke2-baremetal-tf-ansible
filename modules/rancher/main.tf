# Define multiple projects using a for_each loop
# Define multiple projects using a for_each loop
resource "rancher2_project" "ci_cd_projects" {
  for_each         = var.projects
  name             = each.value.project_name
  wait_for_cluster = true
  cluster_id       = each.value.cluster_id
}


# resource "rancher2_namespace" "ci_cd_namespaces" {
#   for_each         = var.projects
#   name             = each.value.namespace_name
#   project_id       = rancher2_project.ci_cd_projects[each.key].id
#   wait_for_cluster = true
#   depends_on       = [rancher2_project.ci_cd_projects]
# }

# resource "rancher2_project" "downstream_ci_cd_projects" {
#   for_each         = var.projects
#   name             = each.value.project_name
#   wait_for_cluster = true
#   cluster_id       = rancher2_cluster.downstream_import.id
# }
resource "rancher2_app_v2" "cis_benchmark_rancher" {
  cluster_id = "local"
  name       = "rancher-cis-benchmark"
  namespace  = "cis-operator-system"
  repo_name  = "rancher-charts"
  chart_name = "rancher-cis-benchmark"
  depends_on = [rancher2_cluster.downstream_import]
}


# resource "rancher2_cloud_credential" "vsphere_credential_config" {
#   name = var.vsphere_credential_name
#   vsphere_credential_config {
#     vcenter_port = 443
#     vcenter      = var.vsphere_server
#     username     = var.vsphere_username
#     password     = var.vsphere_password
#   }
# }

# resource "rancher2_cluster" "downstream_import" {
#   name        = var.downstrem_cluster_name
#   labels      = var.cluster_labels
#   description = var.downstream_cluster_description
# }



