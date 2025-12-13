// ============================================================================
// Bicep Template: Main Infrastructure Deployment
// Description: Deploys Azure Resource Group with naming convention
// ============================================================================

targetScope = 'subscription'

@description('Project name (lowercase, no spaces)')
param projectName string

@description('Azure region for resource group (e.g., eastus, westus, northeurope)')
param location string


// ============================================================================
// Variables
// ============================================================================

// Generate a unique suffix using subscription ID hash (8 characters)
var uniqueSuffix = substring(uniqueString(subscription().id), 0, 8)

// Resource group name following Azure naming conventions
var resourceGroupName = 'rg-${projectName}-${location}-${uniqueSuffix}'

// ============================================================================
// Resources
// ============================================================================

// Create Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: {
    deployedBy: 'Bicep'
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('Resource Group ID')
output resourceGroupId string = resourceGroup.id

@description('Resource Group Name')
output resourceGroupName string = resourceGroup.name

@description('Resource Group Location')
output resourceGroupLocation string = resourceGroup.location

@description('Unique Suffix used for naming')
output uniqueSuffix string = uniqueSuffix
