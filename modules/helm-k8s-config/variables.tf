variable "kubeconfig_server_address" {
  description = "The address of the server hosting the kubeconfig file"
  type        = string
  default     = ""
}

variable "ssh_port" {
  description = "SSH port"
  type        = number
  default     = 22
}

variable "ssh_private_key" {
  description = "Path to the SSH private key"
  type        = string
  default     = ""
}

variable "enable_rke2_cluster_api" {
  type        = bool
  default     = false
  description = "Enable RKE2 cluster API access"
}

variable "manager_rke2_api_dns" {
  type        = string
  default     = ""
  description = "DNS name for the RKE2 API server. If not set, the IP address of the first control plane node will be used."
}

variable "cluster_name" {
  description = "Name of the RKE2 cluster"
  type        = string
  default     = "rke2-cluster"
}

variable "create_kubeconfig" {
  description = "Create a kubeconfig file"
  type        = bool
  default     = true
}

variable "manager_rke2_api_ip" {
  type        = string
  default     = ""
  description = "The IP address for the RKE2 API. If not set, the IP address of the first control plane node will be used."
}
