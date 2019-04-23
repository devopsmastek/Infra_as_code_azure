provider "azurerm" {
  # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
  version = "=1.24.0"

  subscription_id = "05ec1026-b7a2-4fdf-8bfc-0c93d5ba7db6"
}

variable "prefix" {
  default = "ansible"
}


resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = "West US 2"
}


resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_security_group" "test" {
  name                = "acceptanceTestSecurityGroup1"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
}


resource "azurerm_network_security_group" "test2" {
  name                = "acceptanceTestSecurityGroup"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
}




resource "azurerm_network_security_rule" "outboundinbound" {
  name                        = "tcpport1"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.main.name}"
  network_security_group_name = "${azurerm_network_security_group.test.name}"
   
 }

resource "azurerm_network_security_rule" "inbound" {
  name                        = "tcpport"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.main.name}"
  network_security_group_name = "${azurerm_network_security_group.test2.name}"
}


resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP2"
    location                     = "${azurerm_resource_group.main.location}"
    resource_group_name          = "${azurerm_resource_group.main.name}"
    allocation_method            = "Dynamic"

    tags {
        environment = "dev"
    }
}



resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.test.id}"
  network_security_group_id = "${azurerm_network_security_group.test2.id}"
  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
    delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
   delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk001093"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "ubuntu"
    admin_password = "Password12345!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

#provisioner "file" {
#    source = "playbook.yml"
#    destination = "/home/ubuntu/playbook.yml"
#     }



  provisioner "remote-exec" {

    inline = [
      "sleep 60",
      "sudo apt-get update",
      "sleep 30",
      "sudo apt-get install software-properties-common",
      "sleep 30",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sleep 30",
      "sudo apt-get install ansible -y",
      "sleep 90",
      "ansible --version",
      "git clone -b dev  https://devopsmastek:Mastek%401234@github.com/devopsmastek/assemblyline.git",
      "sleep 30",
      "sudo -H  ansible-playbook  /home/ubuntu/assemblyline/ansible/playbook.yml",
      "sleep 90"]}


      

  connection {
      type = "ssh",
      user = "ubuntu"
      password = "Password12345!"
      timeout = "3m"
      agent = false
      }

  tags = {
    environment = "dev"}

}
