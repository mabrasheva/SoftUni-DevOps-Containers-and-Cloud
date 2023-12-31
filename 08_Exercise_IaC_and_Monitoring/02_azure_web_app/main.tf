# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.75.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

# Generate a random integer to create a globally uniquie name
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = "ContactBookRG${random_integer.ri.result}"
  location = "West Europe"
}

# Create the Linux App Service Plan
resource "azurerm_service_plan" "asp" {
  name                = "contact-book-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

# Create the web app, pass in rge App Service Plan ID
resource "azurerm_linux_web_app" "lwa" {
  name                = "contact-book-linux-web-app-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      node_version = "16-lts"
    }
    always_on = false
  }
}

# Deploy code from a public GitHub repo
resource "azurerm_app_service_source_control" "assc" {
  app_id                 = azurerm_linux_web_app.lwa.id
  repo_url               = "https://github.com/nakov/ContactBook.git"
  branch                 = "master"
  use_manual_integration = true
}