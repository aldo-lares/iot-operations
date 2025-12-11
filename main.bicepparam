using './main.bicep'

// ============================================================================
// Parameters for Ubuntu VM deployment
// ============================================================================

// Location where resources will be deployed
param location = 'eastus'

// Virtual Machine settings
param vmName = 'ubuntu-vm'
param vmSize = 'Standard_B2s'

// Admin credentials
param adminUsername = 'azureuser'
// Note: You must provide the SSH public key during deployment
// Example: bicep deploy ... --parameters adminSshKey='ssh-rsa AAAAB3...'
param adminSshKey = readEnvironmentVariable('SSH_PUBLIC_KEY', '')

// Ubuntu version
param ubuntuOSVersion = '22.04-LTS'

// Network settings
param vnetName = 'ubuntu-vnet'
param vnetAddressPrefix = '10.0.0.0/16'
param subnetName = 'default'
param subnetAddressPrefix = '10.0.0.0/24'
param nsgName = 'ubuntu-nsg'
