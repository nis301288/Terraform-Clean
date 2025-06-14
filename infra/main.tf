provider "azurerm" {
  features {}
  subscription_id = "3104174e-e21e-419c-b8ae-f3d80dcf0022"
}

resource "azurerm_resource_group" "example" {
  name     = "terraform-rg"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "terraform-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "terraform-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "terraform-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

// This is for Prometheus
# resource "azurerm_public_ip" "prometheus_public_ip" {
#   name                = "prometheus-public-ip"
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

// This is for Grafana
resource "azurerm_public_ip" "grafana_public_ip" {
  name                = "grafana-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "prometheus_nic" {
  name                = "prometheus-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "prometheus-ipconfig"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    # No public_ip_address_id here
    //public_ip_address_id          = azurerm_public_ip.prometheus_public_ip.id
  }
}

resource "azurerm_network_interface" "grafana_nic" {
  name                = "grafana-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "grafana-ipconfig"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.grafana_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "prometheus" {
  name                = "prometheus-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  # network_interface_ids = [azurerm_network_interface.prometheus_nic.id]

  network_interface_ids = [
    azurerm_network_interface.prometheus_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "grafana" {
  name                = "grafana-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

   network_interface_ids = [
    azurerm_network_interface.grafana_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

output "grafana_public_ip" {
  value = azurerm_public_ip.grafana_public_ip.ip_address
}

resource "azurerm_network_security_group" "monitoring_nsg" {
  name                = "monitoring-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "allow-prometheus-and-grafana"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["9090", "3000", "22"] # Include SSH for debugging
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

// This is for Terraform VPN
resource "azurerm_public_ip" "example" {
  name                = "terraform-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"      # ✅ Required for Standard SKU
  sku                 = "Standard"    # Explicitly define SKU
}


resource "azurerm_linux_virtual_machine" "example" {
  name                = "terraform-linux-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  admin_ssh_key {
  username   = "azureuser"
  public_key = file("id_rsa.pub")
}
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
