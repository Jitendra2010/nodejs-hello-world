
# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "three-tier-rg"
  location = "East US"
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "three-tier-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

# Create Subnets
resource "azurerm_subnet" "frontend" {
  name                 = "frontend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "database" {
  name                 = "database-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Create Network Security Groups (NSGs)
resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "frontend-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "backend_nsg" {
  name                = "backend-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_group" "database_nsg" {
  name                = "database-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Frontend NSG Rules (Allow HTTP & HTTPS)
resource "azurerm_network_security_rule" "frontend_allow_web" {
  resource_group_name         = azurerm_resource_group.rg.name  
  name                        = "allow-http-https"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.frontend_nsg.name
}

# Backend NSG Rules (Allow only from Frontend)
resource "azurerm_network_security_rule" "backend_allow_frontend" {
  resource_group_name         = azurerm_resource_group.rg.name
  name                        = "allow-frontend-to-backend"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefix       = "10.0.1.0/24"
  destination_address_prefix  = "10.0.2.0/24"
  network_security_group_name = azurerm_network_security_group.backend_nsg.name
}

# # Database NSG Rules (Allow only from Backend)
resource "azurerm_network_security_rule" "database_allow_backend" {
              resource_group_name         = azurerm_resource_group.rg.name
              name                        = "allow-backend-to-database"
              priority                    = 100
              direction                   = "Inbound"
              access                      = "Allow"
              protocol                    = "Tcp"
              source_port_range           = "*"
              destination_port_range      = "3306"
              source_address_prefix       = "10.0.2.0/24"
              destination_address_prefix  = "10.0.3.0/24"
              network_security_group_name = azurerm_network_security_group.database_nsg.name
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "frontend_assoc" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "backend_assoc" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "database_assoc" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database_nsg.id
}

# NAT Gateway (For Private Subnet Internet Access)
resource "azurerm_public_ip" "nat_ip" {
  name                = "nat-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat_gw" {
  name                = "nat-gateway"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gw.id
  public_ip_address_id = azurerm_public_ip.nat_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_backend" {
  subnet_id      = azurerm_subnet.backend.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}

resource "azurerm_subnet_nat_gateway_association" "nat_database" {
  subnet_id      = azurerm_subnet.database.id
  nat_gateway_id = azurerm_nat_gateway.nat_gw.id
}



