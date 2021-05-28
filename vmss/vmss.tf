terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.58.0"
    }
  }
}

provider "azurerm" {
  version         = ">= 2.0"
  features {}
}

resource "azurerm_lb" "lb" {
  name                = "vmss-lb"
  location            = var.location
  resource_group_name = var.resourceGroupName

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_resource_group.similarity.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = var.resourceGroupName
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_pool" "lbnatpool" {
  resource_group_name            = "${azurerm_resource_group.similarity.name}"
  name                           = "ssh"
  loadbalancer_id                = "${azurerm_lb.vmss_lb.id}"
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50119
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_probe" "probe" {
  resource_group_name = "${azurerm_resource_group.similarity.name}"
  loadbalancer_id     = "${azurerm_lb.vmss_lb.id}"
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/health"
  port                = 8080
}

resource "azurerm_virtual_machine_scale_set" "example" {
  name                = "dockerswarm-1"
  location            = "${azurerm_resource_group.similarity.location}"
  resource_group_name = "${azurerm_resource_group.similarity.name}"

  # automatic rolling upgrade
  automatic_os_upgrade = true
  upgrade_policy_mode  = "Rolling"

  rolling_upgrade_policy {
    max_batch_instance_percent              = 20
    max_unhealthy_instance_percent          = 20
    max_unhealthy_upgraded_instance_percent = 5
    pause_time_between_batches              = "PT0S"
  }

  # required when using rolling upgrade policy
  health_probe_id = "${azurerm_lb_probe.probe.id}"

  sku {
    name     = "Standard_F2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "swarmvm"
    admin_username       = "admin"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/myadmin/.ssh/authorized_keys"
      key_data = file("~/.ssh/demo_key.pub")
    }
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "TestIPConfiguration"
      primary                                = true
      subnet_id                              = "${azurerm_subnet.subnet.id}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.bpepool.id}"]
      load_balancer_inbound_nat_rules_ids    = ["${azurerm_lb_nat_pool.lbnatpool.id}"]
    }
  }

  tags = {
    environment = "staging"
  }
}
