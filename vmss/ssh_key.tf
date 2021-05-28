resource "azurerm_ssh_public_key" "sshkey" {
  name                = "similarity-sshkey"
  resource_group_name = "${azurerm_resource_group.similarity.name}"
  location            = "${azurerm_resource_group.similarity.location}"
  public_key          = file("~/.ssh/id_rsa.pub")
}