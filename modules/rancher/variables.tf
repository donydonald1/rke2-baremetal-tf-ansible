variable "vsphere_username" {
  description = "vSphere username"
  type = string

}

variable "vsphere_password" {
  description = "vSphere password"
  type = string

}

variable "vsphere_server" {
  description = "vSphere server"
  type = string

}

variable "vsphere_credential_name" {
  description = "vSphere credential name"
  type = string
  default = "vsphere-admin"

}

variable "projects" {
  type = map(object({
    project_name   = string
    namespace_name = string
    cluster_id     = string
  }))
  default = {
    "ci_cd_project" = {
      project_name   = "ci-cd-project"
      namespace_name = "ci-cd"
      cluster_id     = "local"
    },
    "another_project" = {
      project_name   = "another-project"
      namespace_name = "another-namespace"
      cluster_id     = "local"
    }
  }
}

variable "project_names" {
  description = "The names of the projects to create."
  type        = list(string)
  default     = ["ci-cd-project", "monitoring-project", "logging-project", "security-project"]

}

variable "downstrem_cluster_name" {
  description = "Downstream cluster name"
  type = string
  default = "downstream-cluster"

}

variable "downstream_cluster_version" {
  description = "Downstream cluster version"
  type = string
  default = "v1.31.2+rke2r1"

}

variable "downstream_cluster_description" {
  description = "application team cluster"
  type = string
  default = "Downstream cluster"

}
variable "cluster_labels" {
  description = "Cluster labels"
  type = map(string)
  default = {
    "cluster" = "downstream"
    "created" = "true"
    "imported" = "true"
    "owner" = "Donald_Etsecom"
  }

}

variable "wait" {
  description = "An optional wait before installing the Rancher helm chart (seconds)"
  default     = "180s"
}
