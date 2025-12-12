// ============================================================================
// Subscription-level Bicep template
// Creates resource group and deploys VM infrastructure
// ============================================================================

targetScope = 'subscription'

@description('Base name of the resource group to create (unique suffix will be added)')
param resourceGroupName string = 'rg-iot-operations'

@description('Location for the resource group and all resources')
param location string = 'eastus'

@description('Optional suffix seed to force a new RG name per deployment; defaults to a new GUID')
param deploymentSuffix string = newGuid()

// ============================================================================
// Variables
// ============================================================================

// Generate unique suffix (5 chars) per deployment using subscription ID and provided seed
var uniqueSuffix = substring(uniqueString('${subscription().subscriptionId}-${deploymentSuffix}'), 0, 5)
var resourceGroupNameWithSuffix = '${resourceGroupName}-${uniqueSuffix}'

@description('Name of the virtual machine')
param vmName string = 'ubuntu-vm'

@description('Size of the virtual machine')
param vmSize string = 'Standard_B2s'

@description('Admin username for the virtual machine')
param adminUsername string = 'azureuser'

@description('SSH public key for authentication')
@secure()
param adminSshKey string

@description('Ubuntu OS version')
@allowed([
  '24.04-LTS'
  '22.04-LTS'
  '20.04-LTS'
  '18.04-LTS'
])
param ubuntuOSVersion string = '24.04-LTS'

@description('Name of the virtual network')
param vnetName string = 'ubuntu-vnet'

@description('Address prefix for the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Name of the subnet')
param subnetName string = 'default'

@description('Address prefix for the subnet')
param subnetAddressPrefix string = '10.0.0.0/24'

@description('Name of the network security group')
param nsgName string = 'ubuntu-nsg'

// ============================================================================
// Resource Group
// ============================================================================

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupNameWithSuffix
  location: location
}

// ============================================================================
// VM Infrastructure Module
// ============================================================================

module vmInfrastructure 'main.bicep' = {
  scope: rg
  name: 'vm-infrastructure-deployment'
  params: {
    location: location
    vmName: vmName
    vmSize: vmSize
    adminUsername: adminUsername
    adminSshKey: adminSshKey
    ubuntuOSVersion: ubuntuOSVersion
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    subnetName: subnetName
    subnetAddressPrefix: subnetAddressPrefix
    nsgName: nsgName
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Name of the created resource group')
output resourceGroupName string = rg.name

@description('Public IP address of the virtual machine')
output publicIpAddress string = vmInfrastructure.outputs.publicIpAddress

@description('FQDN of the virtual machine')
output fqdn string = vmInfrastructure.outputs.fqdn

@description('SSH command to connect to the VM')
output sshCommand string = vmInfrastructure.outputs.sshCommand

@description('Resource ID of the virtual machine')
output vmId string = vmInfrastructure.outputs.vmId
