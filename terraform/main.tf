locals {
  virtual_machine_image_linux = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  virtual_machine_image_windows = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-with-Containers"
    version   = "latest"
  }
}

# Create a Resource Group for the new Virtual Machine.
resource "azurerm_resource_group" "main" {
  name     = "${var.azure_resource_group}"
  location = "${var.azure_resource_location}"
}

# Create a Virtual Network within the Resource Group
resource "azurerm_virtual_network" "main" {
  name                = "cluster-network"
  address_space       = ["172.16.0.0/16"]
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
}

# Create a Subnet within the Virtual Network
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  address_prefix       = "172.16.1.0/24"
}

# Create a Network Security Group with some rules
resource "azurerm_network_security_group" "main" {
  name                = "cluster-nsg"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  security_rule {
    name                       = "allow_SSH"
    description                = "Allow SSH access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_RDP"
    description                = "Allow RDP access"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_WinRM"
    description                = "Allow WinRM access"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_Prometheus"
    description                = "Allow Prometheus access"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_Grafana"
    description                = "Allow Grafana access"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

/*
  Linux machines
*/

# Create a Public IP
resource "azurerm_public_ip" "computes_linux" {
  count = "${var.cluster_nodes_linux}"

  name                         = "cluster-linux-ip-${count.index}"
  location                     = "${azurerm_resource_group.main.location}"
  resource_group_name          = "${azurerm_resource_group.main.name}"
  public_ip_address_allocation = "dynamic"

  domain_name_label = "cluster-ln${count.index}"
}

# Create a network interface for VMs and attach the PIP and the NSG
resource "azurerm_network_interface" "computes_linux" {
  count = "${var.cluster_nodes_linux}"

  name                      = "cluster-linux-interface-${count.index}"
  location                  = "${azurerm_resource_group.main.location}"
  resource_group_name       = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.computes_linux.*.id, count.index)}"
  }
}

# Create a new Virtual Machines
resource "azurerm_virtual_machine" "computes_linux" {
  count = "${var.cluster_nodes_linux}"

  name                             = "cluster-linux-${count.index}"
  location                         = "${azurerm_resource_group.main.location}"
  resource_group_name              = "${azurerm_resource_group.main.name}"
  network_interface_ids            = ["${element(azurerm_network_interface.computes_linux.*.id, count.index)}"]
  vm_size                          = "Standard_DS2_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference = ["${local.virtual_machine_image_linux}"]

  os_profile = {
    computer_name  = "cluster-linux-${count.index}"
    admin_username = "${var.admin_username}"
  }

  os_profile_linux_config = {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
  }

  storage_os_disk {
    name              = "cluster-linux-cdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "40"
  }

  tags {
    group = "linux"
  }
}

/*
  Windows Compute
*/

# Create a Public IP
resource "azurerm_public_ip" "computes_win" {
  count = "${var.cluster_nodes_windows}"

  name                         = "cluster-win-ip-${count.index}"
  location                     = "${azurerm_resource_group.main.location}"
  resource_group_name          = "${azurerm_resource_group.main.name}"
  public_ip_address_allocation = "dynamic"

  domain_name_label = "cluster-wn${count.index}"
}

# Create a network interface for VMs and attach the PIP and the NSG
resource "azurerm_network_interface" "computes_win" {
  count = "${var.cluster_nodes_windows}"

  name                      = "cluster-win-interface-${count.index}"
  location                  = "${azurerm_resource_group.main.location}"
  resource_group_name       = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.computes_win.*.id, count.index)}"
  }
}

# Create a new Virtual Machines
resource "azurerm_virtual_machine" "computes_win" {
  count = "${var.cluster_nodes_windows}"

  name                             = "cluster-win-${count.index}"
  location                         = "${azurerm_resource_group.main.location}"
  resource_group_name              = "${azurerm_resource_group.main.name}"
  network_interface_ids            = ["${element(azurerm_network_interface.computes_win.*.id, count.index)}"]
  vm_size                          = "Standard_DS2_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference = ["${local.virtual_machine_image_windows}"]

  os_profile = {
    computer_name  = "cluster-win-${count.index}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_windows_config = {
    enable_automatic_upgrades = true
  }

  storage_os_disk {
    name              = "cluster-win-cdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = "130"                              # The default image is very large, this explains the large disk size
  }

  tags {
    group = "windows"
  }
}
