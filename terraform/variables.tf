variable "admin_username" {
  description = "The username associated with the local administrator account on the Virtual Machine"
}

variable "admin_password" {
  description = "The password associated with the local administrator account on the Windows Virtual Machine. For Linux machines the local ssh key is used"
}

variable "azure_resource_group" {
  description = "Name of the resource group to use in Azure"
}

variable "azure_resource_location" {
  description = "Location of the resource group"
}

variable "cluster_nodes_linux" {
  description = "Number of Linux worker nodes"
}

variable "cluster_nodes_windows" {
  description = "Number of Windows worker nodes"
}
