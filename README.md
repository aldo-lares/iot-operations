# IoT Operations - Ubuntu VM Deployment

This repository contains a basic Bicep project to deploy an Ubuntu virtual machine in Azure.

## Overview

This Bicep template deploys a complete Ubuntu virtual machine infrastructure in Azure, including:

- **Virtual Machine**: Ubuntu Server (22.04 LTS by default)
- **Virtual Network**: With configurable address space
- **Subnet**: Default subnet with network security group association
- **Network Security Group**: With SSH access rule
- **Public IP Address**: Static public IP with DNS label
- **Network Interface**: Connected to the VM

## Prerequisites

- Azure CLI installed ([Installation guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- Bicep CLI installed ([Installation guide](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install))
- An Azure subscription
- SSH key pair for authentication

## Quick Start

### Automated Deployment (Recommended)

Use the included deployment script for a streamlined deployment:

```bash
# Make the script executable (if not already)
chmod +x deploy.sh

# Deploy with default settings
./deploy.sh

# Or specify custom resource group and SSH key
./deploy.sh my-resource-group ~/.ssh/my_key.pub
```

The script will:
- Check prerequisites (Azure CLI, Bicep, SSH key)
- Create the resource group
- Deploy the VM infrastructure
- Display connection information

### Manual Deployment

#### 1. Generate SSH Key (if you don't have one)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key
```

#### 2. Login to Azure

```bash
az login
```

#### 3. Create a Resource Group

```bash
az group create --name rg-ubuntu-vm --location eastus
```

#### 4. Deploy the Template

You can deploy using either the Azure CLI or parameters file:

##### Option A: Using Azure CLI with inline parameters

```bash
az deployment group create \
  --resource-group rg-ubuntu-vm \
  --template-file main.bicep \
  --parameters adminSshKey="$(cat ~/.ssh/azure_vm_key.pub)"
```

##### Option B: Using parameters file

First, set the SSH public key as an environment variable:

```bash
export SSH_PUBLIC_KEY="$(cat ~/.ssh/azure_vm_key.pub)"
```

Then deploy:

```bash
az deployment group create \
  --resource-group rg-ubuntu-vm \
  --template-file main.bicep \
  --parameters main.bicepparam
```

##### Option C: Override specific parameters

```bash
az deployment group create \
  --resource-group rg-ubuntu-vm \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters vmName=my-ubuntu-vm \
  --parameters location=westus2
```

#### 5. Get Connection Information

After deployment completes, retrieve the output values:

```bash
az deployment group show \
  --resource-group rg-ubuntu-vm \
  --name main \
  --query properties.outputs
```

Or connect directly:

```bash
# Get the SSH command from outputs
SSH_COMMAND=$(az deployment group show \
  --resource-group rg-ubuntu-vm \
  --name main \
  --query properties.outputs.sshCommand.value -o tsv)

# Connect using your private key
$SSH_COMMAND -i ~/.ssh/azure_vm_key
```

## Configuration Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| `location` | Azure region for resources | `eastus` |
| `vmName` | Name of the virtual machine | `ubuntu-vm` |
| `vmSize` | Azure VM size | `Standard_B2s` |
| `adminUsername` | Admin username for the VM | `azureuser` |
| `adminSshKey` | SSH public key for authentication | (required) |
| `ubuntuOSVersion` | Ubuntu version (22.04-LTS, 20.04-LTS, 18.04-LTS) | `22.04-LTS` |
| `vnetName` | Virtual network name | `ubuntu-vnet` |
| `vnetAddressPrefix` | VNet address space | `10.0.0.0/16` |
| `subnetName` | Subnet name | `default` |
| `subnetAddressPrefix` | Subnet address space | `10.0.0.0/24` |
| `nsgName` | Network security group name | `ubuntu-nsg` |

## Outputs

The template provides the following outputs:

- `publicIpAddress`: The public IP address of the VM
- `fqdn`: The fully qualified domain name of the VM
- `sshCommand`: Ready-to-use SSH command to connect to the VM
- `vmId`: Azure resource ID of the virtual machine

## Security Considerations

⚠️ **Important Security Notes:**

- The template uses SSH key authentication (password authentication is disabled) ✅
- **WARNING**: The default NSG configuration allows SSH access from ANY source IP (`*`). This is suitable for development/testing but creates a security risk in production environments.
- **For production use**: Edit `main.bicep` line 79 to restrict SSH access to your specific IP address or range:
  ```bicep
  sourceAddressPrefix: 'YOUR.IP.ADDRESS.HERE/32'  // Replace with your IP
  ```
- The VM uses a static public IP for consistent access
- Consider using Azure Bastion for more secure SSH access without exposing port 22 to the internet
- Regularly update your Ubuntu VM with security patches after deployment

## Customization Examples

### Deploy with different VM size

```bash
az deployment group create \
  --resource-group rg-ubuntu-vm \
  --template-file main.bicep \
  --parameters adminSshKey="$(cat ~/.ssh/azure_vm_key.pub)" \
  --parameters vmSize=Standard_D2s_v3
```

### Deploy Ubuntu 20.04 LTS

```bash
az deployment group create \
  --resource-group rg-ubuntu-vm \
  --template-file main.bicep \
  --parameters adminSshKey="$(cat ~/.ssh/azure_vm_key.pub)" \
  --parameters ubuntuOSVersion=20.04-LTS
```

### Deploy in different region

```bash
az deployment group create \
  --resource-group rg-ubuntu-vm \
  --template-file main.bicep \
  --parameters adminSshKey="$(cat ~/.ssh/azure_vm_key.pub)" \
  --parameters location=westeurope
```

## Clean Up

To delete all resources created by this template:

```bash
az group delete --name rg-ubuntu-vm --yes --no-wait
```

## Validation

To validate the Bicep template without deploying:

```bash
bicep build main.bicep
```

Or use Azure CLI:

```bash
az deployment group validate \
  --resource-group rg-ubuntu-vm \
  --template-file main.bicep \
  --parameters adminSshKey="$(cat ~/.ssh/azure_vm_key.pub)"
```

## Files in this Repository

- `main.bicep`: Main Bicep template defining the infrastructure
- `main.bicepparam`: Parameters file with default values
- `deploy.sh`: Automated deployment script (recommended for quick start)
- `README.md`: This documentation file
- `.gitignore`: Git ignore file excluding build artifacts

## Troubleshooting

### SSH Connection Issues

If you cannot connect via SSH:

1. Verify the NSG rules allow SSH (port 22)
2. Check that you're using the correct private key
3. Ensure the VM has finished provisioning
4. Verify the public IP address is correct

### Deployment Failures

If deployment fails:

1. Check that the VM size is available in your chosen region
2. Verify you have sufficient quota for the VM size
3. Ensure the SSH key is in the correct format
4. Review the deployment error message for specific issues

## License

This project is provided as-is for educational and operational purposes.