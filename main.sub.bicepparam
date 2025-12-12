using './main.sub.bicep'

// ============================================================================
// Parameters for subscription-level deployment
// ============================================================================

// Resource Group settings
param resourceGroupName = 'rg-iot-operations'
param location = 'westus2'

// Virtual Machine settings
param vmName = 'ubuntu-vm'
param vmSize = 'Standard_B2s'

// Admin credentials
param adminUsername = 'azureuser'
// IMPORTANT: SSH key must be provided via environment variable or Key Vault
// Set environment variable: $env:SSH_PUBLIC_KEY = "ssh-rsa AAAAB3..."
param adminSshKey = readEnvironmentVariable('SSH_PUBLIC_KEY', '')

// Ubuntu version
param ubuntuOSVersion = '22.04-LTS'

// Network settings
param vnetName = 'ubuntu-vnet'
param vnetAddressPrefix = '10.0.0.0/16'
param subnetName = 'default'
param subnetAddressPrefix = '10.0.0.0/24'
param nsgName = 'ubuntu-nsg'
