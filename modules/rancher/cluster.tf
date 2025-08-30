# locals {
#   # Generate individual node configurations based on `node_groups`
#   nodes = flatten([
#     for group_name, group_config in var.node_groups : [
#       for index in range(group_config.quantity) : {
#         group_name  = group_name
#         vmname      = group_config.vmname[index]
#         ip          = group_config.ip[index]
#         subnet_mask = group_config.subnet_mask
#         gateway     = group_config.gateway
#         nameservers = group_config.nameservers
#         cpu_count   = group_config.cpu_count
#         disk_size   = group_config.disk_size
#         memory_size = group_config.memory_size
#         template_name = group_config.template_name
#         datastore_cluster = group_config.datastore_cluster
#       }
#     ]
#   ])
# }

# resource "rancher2_machine_config_v2" "vsphere_machine_config" {
#   for_each = var.node_groups

#   generate_name = "vsphere-machine-config-${each.key}-"

#   vsphere_config {
#     boot2docker_url   = "https://releases.rancher.com/os/latest/vmware/rancheros.vmdk"
#     content_library   = "Linux-Servers"
#     datacenter        = "Techsecom-PL-DC"
#     memory_size       = each.value.memory_size
#     disk_size         = each.value.disk_size
#     cpu_count         = each.value.cpu_count
#     network           = ["VM Network"]
#     clone_from        = each.value.template_name
#     datastore         = "datastore3"
#     creation_type     = "library"
#     pool              = "Kubernetes"
#     cfgparam          = ["disk.enableUUID=TRUE"]
#     vcenter           = var.vsphere_server
#     username          = var.vsphere_username
#     vapp_ip_protocol = "IPv4"
#     vapp_ip_allocation_policy = "fixedAllocated"
#     vapp_transport = "com.vmware.guestInfo"
#     vapp_property = [
#         "guestinfo.hostname=${each.value.vmname[0]}", # Add hostname
#         "iguestinfo.ipaddress=${each.value.ip[0]}",
#         "guestinfo.netmask=${each.value.subnet_mask}",
#         "guestinfo.gateway=${each.value.gateway}",
#         "guestinfo.dns=${each.value.nameservers[0]}",
#         "guestinfo.dns2=${each.value.nameservers[1]}",
#         "guestinfo.domain=${each.value.vmname[0]}",
#         "guestinfo.sshkey=true",
        
#     ]
#     password          = var.vsphere_password
#     vcenter_port      = 443
#     cloudinit = (templatefile("${path.module}/templates/metadata.yaml", {
#       hostname                = each.value.vmname[0] # Use the first VM in the group as an example
#       fqdn                    = each.value.vmname[0]
#       ip                      = each.value.ip[0] 
#       subnet                  = each.value.subnet_mask
#       gateway     = each.value.gateway,
#       nameservers = each.value.nameservers
#     }))
#     cloud_config = templatefile("${path.module}/templates/userdata.yaml", {
# # Use the first IP in the group as an example
#       fqdn                    = each.value.vmname[0]
#       hostname                = each.value.vmname[0] # Use the first VM in the group as an example
#       fqdn                    = each.value.vmname[0]
#       ip                      = each.value.ip[0] 
#       subnet                  = each.value.subnet_mask
#       gateway     = each.value.gateway,
#       nameservers = each.value.nameservers
#       rhsm_username           = "donald.etsecom@kyndryl.com"
#       rhsm_password           = "caniseeU@1"
#       timezone                = "America/Chicago"
#       ssh_authorized_keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdMqZ+uS71JDuuEfv8/En8Ow1a9nNv/VkmVZsQOI/W7 donald production mac"]
#     })
#   }
# }



# variable "node_groups" {
#   description = "Configuration for node groups. Each key represents a node group with specific properties."
#   type = map(
#     object({
#       control_plane_role = bool
#       etcd_role          = bool
#       vmname             = list(string)
#       worker_role        = bool
#       ip                 = list(string)
#       subnet_mask        = string
#       nameservers        = list(string)
#       gateway            = string
#       quantity           = number
#       cpu_count          = number
#       disk_size          = number
#       memory_size        = number
#       template_name      = string
#       datastore_cluster =  string
#       machine_annotations = map(string)
#     })
#   )

#   default = {
#     dc1-master = {
#       control_plane_role = true
#       etcd_role          = true
#       worker_role        = true
#       vmname             = ["dc1-master-1.techsecoms.com", "dc1-master-2.techsecoms.com", "dc1-master-3.techsecoms.com"]
#       ip                 = ["10.10.0.100", "10.10.0.101", "10.10.0.102"]
#       subnet_mask        = "24"
#       gateway            = "10.10.0.254"
#       nameservers = ["10.10.0.254", "1.1.1.1"]
#       quantity           = 3
#       cpu_count          = 4
#       disk_size          = 100000
#       memory_size        = 8096
#       template_name      = "linux-rhel-9.4-v0.21.0"
#       datastore_cluster =  "Techsecoms-Datastore-Cluster"
#       machine_annotations = {}
#     }
#   }
# }

# # Create a cluster with multiple machine pools
# resource "rancher2_cluster_v2" "foo" {
#   name = "foo"
#   kubernetes_version = "v1.31.4+rke2r1"
#   enable_network_policy = false
#   rke_config {
#     chart_values = <<EOF
#       rancher-vsphere-cpi:
#         vCenter:
#           host: ${var.vsphere_server}
#           port: 443
#           insecureFlag: true
#           datacenters: "Techsecom-PL-DC"
#           username: ${var.vsphere_username}
#           password: ${var.vsphere_password}
#           credentialsSecret:
#             name: "vsphere-cpi-creds"
#             generate: true
#         cloudControllerManager:
#           nodeSelector:
#             node-role.kubernetes.io/control-plane: 'true'

#       rancher-vsphere-csi:
#         vCenter:
#           host: ${var.vsphere_server}
#           port: 443
#           insecureFlag: true
#           datacenters: "Techsecom-PL-DC"
#           username: ${var.vsphere_username}
#           password: ${var.vsphere_password}
#           configSecret:
#             name: "vsphere-config-secret"
#             generate: true
#         csiNode:
#           nodeSelector: 
#             node-role.kubernetes.io/worker: 'true'
#         storageClass:
#           allowVolumeExpansion: true
#           datastoreURL:  "ds:///vmfs/volumes/6710f4aa-06cf84ea-41bc-44a84219d5e2/"

#     EOF
#     # Nodes in this pool have control plane role and etcd roles
#     dynamic "machine_pools" {
#       for_each = var.node_groups
#       content {
#         cloud_credential_secret_name = rancher2_cloud_credential.vsphere_credential_config.id
#         control_plane_role           = machine_pools.value.control_plane_role
#         etcd_role                    = machine_pools.value.etcd_role
#         worker_role                  = machine_pools.value.worker_role
#         name                         = machine_pools.value.vmname[0]

#         # unhealthy_node_timeout_seconds = "3600"
#         quantity                     = machine_pools.value.quantity
#         hostname_length_limit = "10"
#         machine_labels               = try(machine_pools.value.machine_labels, null)
#         annotations                  = try(machine_pools.value.machine_annotations, null)

#         # dynamic "taints" {
#         #   for_each = machine_pools.value.machine_taints
#         #   content {
#         #     key    = taints.value.key
#         #     value  = taints.value.value
#         #     effect = taints.value.effect
#         #   }
#         # }
#         machine_config {
#           kind = rancher2_machine_config_v2.vsphere_machine_config[machine_pools.key].kind
#           name = replace(rancher2_machine_config_v2.vsphere_machine_config[machine_pools.key].name,machine_pools.value.vmname[0],"-")
#         }
#       }

#     }
#     machine_global_config = <<EOF
#       cni: "calico"
#       disable: [ "rke2-ingress-nginx" ]
#     #   etcd-arg: [ "experimental-initial-corrupt-check=true" ] 
#       write-kubeconfig-mode: "0644"
# EOF
#   }
# }

