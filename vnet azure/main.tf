resource "azurerm_resource_group" "similarity" {
  name = var.resourceGroupName
  location = var.location
}

resource "azurerm_network_security_group" "securitygroup" {
  name                = "sgsimilarity"
  location            = "${azurerm_resource_group.similarity.location}"
  resource_group_name = "${azurerm_resource_group.similarity.name}"


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
  resource_group_name         = "${azurerm_resource_group.similarity.name}"
  network_security_group_name = "${azurerm_network_security_group.securitygroup.name}"
}


resource "azurerm_virtual_network" "virtualnetwork" {
  name                = "similarity-vnet"
  location            = "${azurerm_resource_group.similarity.location}"
  resource_group_name = "${azurerm_resource_group.similarity.name}"
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["1.1.1.1", "1.0.0.1"]

}

resource "azurerm_subnet" "subnet" {
  name                 = "similaritysubnet"
  resource_group_name  = "${azurerm_resource_group.similarity.name}"
  virtual_network_name = "${azurerm_virtual_network.virtualnetwork.name}"
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  name                = "similarity-publicip"
  location            = "${azurerm_resource_group.similarity.location}"
  resource_group_name = "${azurerm_resource_group.similarity.name}"
  allocation_method   = "Static"
  ip_version          = "IPV4"

}
