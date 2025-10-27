variable "control_plane_servers" {
  description = "List of control plane servers with name and IP"
  type = list(object({
    name = string
    ip   = string
  }))
}

variable "worker_servers" {
  description = "List of worker servers with name and IP"
  type = list(object({
    name = string
    ip   = string
  }))

  // Optional: guard that IPs look like IPv4
  validation {
    condition     = alltrue([for s in var.worker_servers : can(regex("^((25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)\\.){3}(25[0-5]|2[0-4]\\d|[0-1]?\\d?\\d)$", s.ip))])
    error_message = "Each server.ip must be a valid IPv4 address."
  }
}

variable "private_registry_url" {
  type        = string
  default     = ""
  description = "The URL of the private registry."
}

variable "private_registry_username" {
  type        = string
  default     = ""
  description = "The username for the private registry."
}

variable "private_registry_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "The password for the private registry."
}

variable "private_registry_insecure_skip_verify" {
  type        = bool
  default     = true
  description = "Whether to skip the verification of the private registry."
}

variable "private_registries" {
  description = "RKE2 registries.yml contents. It used to access private docker registries."
  default     = ""
  type        = string
}

variable "dockerhub_registry_auth_username" {
  type        = string
  default     = ""
  description = "The username for the DockerHub registry."

}

variable "dockerhub_registry_auth_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "The password for the DockerHub registry."
}

variable "ssh_user" {
  description = "SSH user for bare-metal servers"
  type        = string
  default     = "root"
}

variable "ssh_private_key_file" {
  description = "SSH private key file for bare-metal servers"
  type        = string
  default     = ""
}

variable "is_rhel" {
  type    = bool
  default = true
}

variable "rhsm_username" {
  description = "Red Hat Subscription Manager username"
  type        = string
  default     = ""
}
variable "rhsm_password" {
  description = "Red Hat Subscription Manager password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_port" {
  description = "SSH port for bare-metal servers"
  type        = number
  default     = 22
}

variable "nfs_server_ip" {
  description = "NFS server IP address"
  type        = string
  default     = ""
}

variable "nfs_shared_dir" {
  description = "NFS subdirectory for the shared directory"
  type        = string
  default     = "rke2_prod_data"
}

variable "nfs_mount_point" {
  description = "Where to mount the NFS export on the host"
  type        = string
  default     = "/mnt/nfs"
}

variable "nfsver" {
  description = "NFS protocol version to use (3 or 4.1)"
  type        = number
  default     = 3
  validation {
    condition     = contains([3, 4.1], var.nfsver)
    error_message = "nfsver must be 3 or 4.1."
  }
}
