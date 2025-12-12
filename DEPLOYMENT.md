# Deployment Guide

This guide explains how to securely deploy the IoT Operations infrastructure to Azure.

## Overview

The deployment creates:
- **Resource Group** (automatically created)
- **Ubuntu Virtual Machine** with all networking infrastructure
- **Public IP** with DNS label for easy access
- **Network Security Group** with SSH access

## Prerequisites

1. **Azure CLI** - [Install here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Bicep CLI** - Installed automatically by the script
3. **Azure Subscription** - Active subscription with appropriate permissions
4. **SSH Key Pair** - For VM authentication

## Deployment Methods

### Method 1: PowerShell Script (Recommended for Windows)

```powershell
# Deploy with defaults
.\deploy.ps1

# Deploy with custom parameters
.\deploy.ps1 -ResourceGroupName "rg-my-iot" -SshKeyPath "$HOME\.ssh\my_key.pub" -Location "westus2"
```

### Method 2: Bash Script (Linux/macOS/WSL)

```bash
# Make executable
chmod +x deploy.sh

# Deploy with defaults
./deploy.sh

# Deploy with custom parameters
./deploy.sh rg-my-iot ~/.ssh/my_key.pub
```

### Method 3: Manual Azure CLI Deployment

#### Step 1: Login to Azure
```powershell
az login
```

#### Step 2: Generate SSH Key (if needed)
```powershell
ssh-keygen -t rsa -b 4096 -f $HOME\.ssh\azure_vm_key
```

#### Step 3: Set Environment Variable
```powershell
# Read your SSH public key
$sshKey = Get-Content "$HOME\.ssh\azure_vm_key.pub" -Raw
$env:SSH_PUBLIC_KEY = $sshKey.Trim()
```

#### Step 4: Deploy
```powershell
# Subscription-level deployment (creates resource group)
az deployment sub create `
  --name "iot-ops-deployment" `
  --location "eastus" `
  --template-file main.sub.bicep `
  --parameters main.sub.bicepparam
```

## Secure Parameter Handling

### Option 1: Environment Variables (Default)

The deployment scripts use the `SSH_PUBLIC_KEY` environment variable:

```powershell
# PowerShell
$env:SSH_PUBLIC_KEY = Get-Content "$HOME\.ssh\id_rsa.pub" -Raw

# Bash/Linux
export SSH_PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)
```

### Option 2: Azure Key Vault (Production Recommended)

```powershell
# 1. Create Key Vault
az keyvault create --name "kv-iot-ops" --resource-group "rg-keyvault" --location "eastus"

# 2. Store SSH key
az keyvault secret set --vault-name "kv-iot-ops" --name "vm-ssh-key" --value "ssh-rsa AAAAB3..."

# 3. Get Key Vault resource ID
$kvId = az keyvault show --name "kv-iot-ops" --query id -o tsv

# 4. Deploy with Key Vault reference
az deployment sub create `
  --name "iot-ops-deployment" `
  --location "eastus" `
  --template-file main.sub.bicep `
  --parameters resourceGroupName="rg-iot-operations" `
  --parameters adminSshKey="@Microsoft.KeyVault(SecretUri=https://kv-iot-ops.vault.azure.net/secrets/vm-ssh-key/)"
```

### Option 3: Secure Parameter File (Not Committed to Git)

Create `secrets.bicepparam` (already in .gitignore):

```bicep
using './main.sub.bicep'

param resourceGroupName = 'rg-iot-operations'
param location = 'eastus'
param adminSshKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB...'
```

Deploy:
```powershell
az deployment sub create `
  --name "iot-ops-deployment" `
  --location "eastus" `
  --template-file main.sub.bicep `
  --parameters secrets.bicepparam
```

## Customization

### Change VM Size
```powershell
.\deploy.ps1 -ResourceGroupName "rg-iot-ops"
# Then modify main.sub.bicepparam: param vmSize = 'Standard_D2s_v3'
```

### Change Ubuntu Version
Edit `main.sub.bicepparam`:
```bicep
param ubuntuOSVersion = '20.04-LTS'  // or '18.04-LTS'
```

### Change Network Configuration
Edit `main.sub.bicepparam`:
```bicep
param vnetAddressPrefix = '172.16.0.0/16'
param subnetAddressPrefix = '172.16.1.0/24'
```

## Post-Deployment

After successful deployment, you'll see output similar to:

```
Deployment Details:
  Resource Group: rg-iot-operations
  Public IP: 20.XXX.XXX.XXX
  FQDN: ubuntu-vm-abc123.eastus.cloudapp.azure.com

Connect to your VM:
  ssh azureuser@ubuntu-vm-abc123.eastus.cloudapp.azure.com
```

### Connect to VM
```bash
ssh azureuser@<your-fqdn>
```

### View Resources
```powershell
az resource list --resource-group rg-iot-operations -o table
```

## Cleanup

To delete all resources:

```powershell
az group delete --name rg-iot-operations --yes --no-wait
```

## Security Best Practices

1. ✅ **Never commit SSH keys** to version control
2. ✅ **Use Key Vault** for production deployments
3. ✅ **Restrict NSG rules** to specific IP addresses (not `*`)
4. ✅ **Rotate SSH keys** regularly
5. ✅ **Enable Azure Monitor** for VM insights
6. ✅ **Use Managed Identities** when possible

## Troubleshooting

### SSH Key Not Found
```powershell
# Generate new key
ssh-keygen -t rsa -b 4096 -f $HOME\.ssh\azure_vm_key
```

### Deployment Fails - Quota Exceeded
- Check your subscription quotas
- Try a different region or VM size

### Cannot Connect to VM
- Verify NSG rules allow your IP
- Check VM is running: `az vm get-instance-view --resource-group rg-iot-operations --name ubuntu-vm`

### Permission Denied
- Ensure you have Contributor or Owner role on the subscription
- Check: `az role assignment list --assignee <your-email>`

## Additional Resources

- [Azure Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [Ubuntu on Azure](https://ubuntu.com/azure)
