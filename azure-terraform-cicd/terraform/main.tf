resource "azurerm_resource_group" "training" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = "training"
    project     = "azure-terraform-cicd"
    managed_by  = "terraform"
  }
}

resource "azurerm_virtual_network" "training" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
}


resource "azurerm_subnet" "frontend" {
  name                 = "web-subnet"
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = azurerm_virtual_network.training.name
  resource_group_name  = azurerm_resource_group.training.name

}


resource "azurerm_subnet" "backend" {
  name                 = "data-subnet"
  address_prefixes     = ["10.0.2.0/24"]
  virtual_network_name = azurerm_virtual_network.training.name
  resource_group_name  = azurerm_resource_group.training.name

}

resource "azurerm_network_security_group" "nsgfrontend" {
  name                = "nsg-frontend"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location

  security_rule {

    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  security_rule {
    name                       = "Allow-SSH-MyIP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "49.47.214.156/32"
    destination_address_prefix = "*"

  }


}

resource "azurerm_network_security_group" "nsgbackend" {
  name                = "nsg-backend"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location


  security_rule {
    name                       = "Allow-SSH-From-Frontend"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-SSH-From-Other-VNet-Sources"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}


resource "azurerm_subnet_network_security_group_association" "frontend" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.nsgfrontend.id
}

resource "azurerm_subnet_network_security_group_association" "backend" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.nsgbackend.id
}

resource "azurerm_public_ip" "vm_public_ip" {
  name                = "pip-linux-vm"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "my-nic"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name

  ip_configuration {

    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = "vm-linux-training"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location
  size                = "Standard_D2s_v5"

  admin_username                  = "azureuser"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("${pathexpand("~")}/.ssh/azure_terraform.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}



output "linux_vm_public_ip" {
  value = azurerm_public_ip.vm_public_ip.ip_address
}

output "linux_vm_private_ip" {
  value = azurerm_network_interface.nic.private_ip_address
}

output "linux_vm_name" {
  value = azurerm_linux_virtual_machine.linux_vm.name
}



#backend linux vm


# Backend Network Interface

resource "azurerm_network_interface" "backend_nic" {
  name                = "nic-backend"
  location            = azurerm_resource_group.training.location
  resource_group_name = azurerm_resource_group.training.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

variable "backend_admin_password" {
  description = "Backend Ubuntu VM password"
  type        = string
  sensitive   = true
}

resource "azurerm_linux_virtual_machine" "backend_vm" {
  name                = "vm-linux-backend"
  resource_group_name = azurerm_resource_group.training.name
  location            = azurerm_resource_group.training.location
  size                = "Standard_D2s_v5"

  admin_username = "azureuser"

  admin_password                  = var.backend_admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.backend_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

output "backend_vm_private_ip" {
  value = azurerm_network_interface.backend_nic.private_ip_address
}

output "backend_vm_name" {
  value = azurerm_linux_virtual_machine.backend_vm.name
}