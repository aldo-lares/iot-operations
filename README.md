# IoT Operations - Ubuntu VM Deployment

This repository contains a Bicep infrastructure-as-code project to deploy an Ubuntu virtual machine in Azure with **automatic resource group creation** and **secure parameter handling**.

## Overview

This deployment creates a complete Ubuntu virtual machine infrastructure in Azure:

- **Resource Group**: Automatically created during deployment
- **Virtual Machine**: Ubuntu Server (22.04 LTS by default)
- **Virtual Network**: With configurable address space
- **Subnet**: Default subnet with network security group association
- **Network Security Group**: With SSH access rule
- **Public IP Address**: Static public IP with DNS label
- **Network Interface**: Connected to the VM

## Prerequisites

- Azure CLI installed ([Installation guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- Bicep CLI (auto-installed by deployment scripts)
- An Azure subscription
- SSH key pair for authentication

## Key Features

✅ **Subscription-level deployment** - Creates resource group automatically  
✅ **Secure parameter handling** - SSH keys via environment variables or Key Vault  
✅ **Cross-platform scripts** - PowerShell and Bash deployment scripts  
✅ **Production-ready** - Modular design with security best practices

## Quick Start

### Automated Deployment (Recommended)

#### PowerShell (Windows)
```powershell
# Deploy with defaults (creates rg-iot-operations)
.\deploy.ps1

# Or customize parameters
.\deploy.ps1 -ResourceGroupName "rg-my-iot" -SshKeyPath "$HOME\.ssh\my_key.pub" -Location "westus2"
```

#### Bash (Linux/macOS/WSL)
```bash
# Make the script executable
chmod +x deploy.sh

# Deploy with defaults
./deploy.sh

# Or specify custom parameters
./deploy.sh rg-my-iot ~/.ssh/my_key.pub
```

The scripts will:
- ✅ Check prerequisites (Azure CLI, Bicep, SSH key)
- ✅ **Automatically create the resource group**
- ✅ Deploy the VM infrastructure
- ✅ Display connection information

> **Note**: The new subscription-level deployment automatically creates the resource group - no manual creation needed!

### Manual Deployment

#### 1. Generate SSH Key (if you don't have one)

```powershell
# PowerShell
ssh-keygen -t rsa -b 4096 -f $HOME\.ssh\azure_vm_key

# Bash/Linux
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key
```

#### 2. Login to Azure

```powershell
az login
```

#### 3. Set SSH Key Environment Variable

```powershell
# PowerShell
$sshKey = Get-Content "$HOME\.ssh\azure_vm_key.pub" -Raw
$env:SSH_PUBLIC_KEY = $sshKey.Trim()

# Bash/Linux
export SSH_PUBLIC_KEY=$(cat ~/.ssh/azure_vm_key.pub)
```

#### 4. Deploy (Subscription-Level - Creates Resource Group Automatically)

```powershell
# PowerShell
az deployment sub create `
  --name "iot-ops-deployment" `
  --location "eastus" `
  --template-file main.sub.bicep `
  --parameters main.sub.bicepparam

# Bash/Linux
az deployment sub create \
  --name "iot-ops-deployment" \
  --location "eastus" \
  --template-file main.sub.bicep \
  --parameters main.sub.bicepparam
```

#### Alternative: Legacy Resource Group Deployment

If you prefer the old method (manual resource group creation):

```powershell
# Create resource group first
az group create --name rg-iot-operations --location eastus

# Deploy to existing resource group
az deployment group create \
  --resource-group rg-iot-operations \
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

- **`main.sub.bicep`**: Subscription-level template (creates resource group + infrastructure)
- **`main.sub.bicepparam`**: Parameters for subscription-level deployment
- **`main.bicep`**: Resource group-level template (VM infrastructure only)
- **`main.bicepparam`**: Parameters for resource group deployment
- **`deploy.ps1`**: PowerShell deployment script (Windows) ⭐
- **`deploy.sh`**: Bash deployment script (Linux/macOS/WSL)
- **`DEPLOYMENT.md`**: Detailed deployment guide with security best practices
- **`README.md`**: This documentation file
- **`.gitignore`**: Protects sensitive files from being committed

## Deployment Architecture

### Subscription-Level Deployment (Recommended)
```
main.sub.bicep (subscription scope)
    ├── Creates Resource Group
    └── Calls main.bicep as module
            └── Creates VM Infrastructure
```

### Resource Group Deployment (Legacy)
```
main.bicep (resource group scope)
    └── Creates VM Infrastructure
    (Requires pre-existing resource group)
```

## Secure Parameter Management

See **[DEPLOYMENT.md](DEPLOYMENT.md)** for detailed security guidance.

### Quick Reference:

**Environment Variables (Default)**
```powershell
$env:SSH_PUBLIC_KEY = Get-Content "$HOME\.ssh\id_rsa.pub" -Raw
```

**Azure Key Vault (Production)**
```powershell
az keyvault secret set --vault-name "kv-iot-ops" --name "vm-ssh-key" --value "ssh-rsa AAAAB3..."
```

**Protected Files** (in .gitignore)
- `secrets.bicepparam` - Local parameter file with secrets
- `*.pub` - SSH public keys
- `*.pem` - SSH private keys

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