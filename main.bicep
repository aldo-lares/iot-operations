// ============================================================================
// Main Bicep template for Ubuntu Virtual Machine deployment
// ============================================================================

@description('Location for all resources')
param location string = resourceGroup().location

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
// Variables
// ============================================================================

var nicName = '${vmName}-nic'
var publicIpName = '${vmName}-pip'
var osDiskName = '${vmName}-osdisk'

// Ubuntu OS image offer mapping based on version
var ubuntuOfferMap = {
  '24.04-LTS': '0001-com-ubuntu-server-noble'
  '22.04-LTS': '0001-com-ubuntu-server-jammy'
  '20.04-LTS': '0001-com-ubuntu-server-focal'
  '18.04-LTS': '0001-com-ubuntu-server-bionic'
}
var ubuntuOffer = ubuntuOfferMap[ubuntuOSVersion]

// Ubuntu OS image SKU mapping based on version (Azure expects underscores)
var ubuntuSkuMap = {
  '24.04-LTS': '24_04-lts'
  '22.04-LTS': '22_04-lts'
  '20.04-LTS': '20_04-lts'
  '18.04-LTS': '18_04-lts'
}
var ubuntuSku = ubuntuSkuMap[ubuntuOSVersion]

// ============================================================================
// Resources
// ============================================================================

// Network Security Group
// NOTE: For production use, restrict SSH access to specific IP addresses
// by replacing '*' in sourceAddressPrefix with your IP address or range
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'  // WARNING: Allows SSH from anywhere. Restrict this in production!
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Public IP Address
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower('${vmName}-${uniqueString(resourceGroup().id)}')
    }
  }
}

// Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminSshKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: ubuntuOffer
        sku: ubuntuSku
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Public IP address of the virtual machine')
output publicIpAddress string = publicIp.properties.ipAddress

@description('FQDN of the virtual machine')
output fqdn string = publicIp.properties.dnsSettings.fqdn

@description('SSH command to connect to the VM')
output sshCommand string = 'ssh ${adminUsername}@${publicIp.properties.dnsSettings.fqdn}'

@description('Resource ID of the virtual machine')
output vmId string = vm.id
