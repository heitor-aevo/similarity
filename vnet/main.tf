terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.58.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_network_security_group" "DockerSwarmSG" {
  name                = "dockerswarmSG"
  location            = "brazilsouth"
  resource_group_name = var.resourceGroupName


}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "SSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.DockerSwarmSG.resource_group_name
  network_security_group_name = azurerm_network_security_group.DockerSwarmSG.name
}


resource "azurerm_virtual_network" "dockerswarm-vnet" {
  name                = "dockerswarm-vnet"
  location            = var.location
  resource_group_name = var.resourceGroupName
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["1.1.1.1", "1.0.0.1"]

}

resource "azurerm_subnet" "dockersawrm-sub" {
  name                 = "testsubnet"
  resource_group_name  = azurerm_network_security_group.DockerSwarmSG.resource_group_name
  virtual_network_name = azurerm_virtual_network.dockerswarm-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "dockerswarm-publicIP" {
  name                = "dockersawrm-publicIP"
  location            = "brazilsouth"
  resource_group_name = azurerm_network_security_group.DockerSwarmSG.resource_group_name
  allocation_method   = "Static"
  ip_version          = "IPV4"

}
