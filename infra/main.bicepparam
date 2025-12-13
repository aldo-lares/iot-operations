using './main.bicep'

// ============================================================================
// Parameters Configuration File
// ============================================================================
// This file contains the parameter values for the Bicep deployment.
// Modify these values according to your deployment needs.

// Minimal parameters
param projectName = 'iotops'
param location = 'eastus'
param adminSshPublicKey = 'ssh-rsa AAAA...'
