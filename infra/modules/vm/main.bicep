@description('Project name (lowercase, no spaces)')
param projectName string

@description('Resource group location (same as RG)')
param location string

@description('Unique suffix (8 chars) to ensure unique naming')
param uniqueSuffix string

@description('Admin username for the VM')
param adminUsername string = 'azureuser'

@secure()
@description('SSH public key for admin user (e.g., ssh-rsa ...)')
param adminSshPublicKey string

@description('VM size')
param vmSize string = 'Standard_B2s'

// Construct base name: vm-<proj>-<loc>-<unique>
var vmName = 'vm-${projectName}-${location}-${uniqueSuffix}'
var vnetName = 'vnet-${projectName}-${location}-${uniqueSuffix}'
var subnetName = 'snet-${projectName}-${location}-${uniqueSuffix}'
var pipName = 'pip-${projectName}-${location}-${uniqueSuffix}'
var nicName = 'nic-${projectName}-${location}-${uniqueSuffix}'
var nsgName = 'nsg-${projectName}-${location}-${uniqueSuffix}'

// NSG allowing SSH inbound
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-ssh'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Public IP
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: pipName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// VNet + Subnet
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [ '10.0.0.0/16' ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// NIC
resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

// Ubuntu 24.04 LTS (Noble) image reference
var imageRef = {
  publisher: 'Canonical'
  offer: 'ubuntu-24_04-lts'
  sku: 'server'
  version: 'latest'
}


// VM
resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
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
              keyData: adminSshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: imageRef
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 30
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

output vmName string = vmName
output publicIpId string = publicIp.id
output publicIpName string = publicIp.name
