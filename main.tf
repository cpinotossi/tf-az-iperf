# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables
variable "location" {
  type    = string
  default = "West Europe"
}

variable "prefix" {
  type    = string
  default = "netperf"
}

variable "myIP" {
  type    = string
  default = "84.128.84.25"
}
# Define Resource Group
resource "azurerm_resource_group" "perf" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags = {
    environment = "perf"
  }
}

resource "azurerm_virtual_network" "perf" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.perf.location
  resource_group_name = azurerm_resource_group.perf.name
  tags = {
    environment = "perf"
  }
}

resource "azurerm_subnet" "bastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.perf.name
  virtual_network_name = azurerm_virtual_network.perf.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_bastion_host" "bastion" {
  name                = "${var.prefix}-bastion"
  location            = azurerm_resource_group.perf.location
  resource_group_name = azurerm_resource_group.perf.name

  ip_configuration {
    name                 = "${var.prefix}-bastion-ipc"
    subnet_id            = azurerm_subnet.bastionSubnet.id
    public_ip_address_id = azurerm_public_ip.bastionPIP.id
  }
}

resource "azurerm_public_ip" "bastionPIP" {
  name                = "${var.prefix}-bastion-ip"
  location            = azurerm_resource_group.perf.location
  resource_group_name = azurerm_resource_group.perf.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "vm1PIP" {
  name                = "${var.prefix}-vm1-ip"
  location            = azurerm_resource_group.perf.location
  resource_group_name = azurerm_resource_group.perf.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_subnet" "perf" {
  name                 = "${var.prefix}-sn"
  resource_group_name  = azurerm_resource_group.perf.name
  virtual_network_name = azurerm_virtual_network.perf.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_network_security_group" "perf" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.perf.location
  resource_group_name = azurerm_resource_group.perf.name
  tags = {
    environment = "perf"
  }
}

resource "azurerm_network_security_rule" "perfNSGRule1" {
  name                        = "${var.prefix}-out-rule"
  priority                    = 100
  direction                   = "outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "${var.myIP}"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.perf.name
  network_security_group_name = azurerm_network_security_group.perf.name
}

resource "azurerm_network_security_rule" "perfNSGRule2" {
  name                        = "${var.prefix}-in-rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "${var.myIP}"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.perf.name
  network_security_group_name = azurerm_network_security_group.perf.name
}

resource "azurerm_subnet_network_security_group_association" "perf" {
  subnet_id                 = azurerm_subnet.perf.id
  network_security_group_id = azurerm_network_security_group.perf.id
}

resource "azurerm_network_interface" "perfVM1" {
  name                = "${var.prefix}-vm1-nic"
  location            = azurerm_resource_group.perf.location
  resource_group_name = azurerm_resource_group.perf.name

  ip_configuration {
    name                          = "${var.prefix}-ipconfig"
    subnet_id                     = azurerm_subnet.perf.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost("10.0.2.0/24", 5)
    public_ip_address_id          = azurerm_public_ip.vm1PIP.id
  }
  tags = {
    environment = "perf"
  }
}

resource "azurerm_linux_virtual_machine" "perfVM1" {
  name                            = "${var.prefix}-linux-01-vm"
  location                        = "${var.location}"
  resource_group_name             = "${azurerm_resource_group.perf.name}"
  size                            = "Standard_F2"
  disable_password_authentication = false
  admin_username                  = "chpinoto"
  admin_password                  = "demo!pass123"
  network_interface_ids = [
    azurerm_network_interface.perfVM1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  tags = {
    environment = "perf"
  }
}
