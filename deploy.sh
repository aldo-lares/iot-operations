#!/bin/bash
# ============================================================================
# Example deployment script for Ubuntu VM
# ============================================================================
# This script demonstrates how to deploy the Ubuntu VM using Azure CLI
# 
# Usage:
#   ./deploy.sh [resource-group-name] [ssh-key-path]
#
# Example:
#   ./deploy.sh rg-ubuntu-vm ~/.ssh/azure_vm_key.pub
# ============================================================================

set -e

# Configuration
RESOURCE_GROUP=${1:-"rg-ubuntu-vm"}
SSH_KEY_PATH=${2:-"$HOME/.ssh/id_rsa.pub"}
LOCATION="eastus"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Ubuntu VM Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Please install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if Bicep is installed
if ! command -v bicep &> /dev/null; then
    echo -e "${YELLOW}Warning: Bicep CLI is not installed${NC}"
    echo "Installing Bicep CLI..."
    az bicep install
fi

# Check if SSH key exists
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${RED}Error: SSH public key not found at $SSH_KEY_PATH${NC}"
    echo ""
    echo "Generate a new SSH key with:"
    echo "  ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_vm_key"
    exit 1
fi

echo -e "${YELLOW}Configuration:${NC}"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  SSH Key: $SSH_KEY_PATH"
echo ""

# Check if logged in to Azure
echo -e "${YELLOW}Checking Azure login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${RED}Not logged in to Azure${NC}"
    echo "Please run: az login"
    exit 1
fi

SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo -e "${GREEN}✓ Logged in to Azure${NC}"
echo "  Subscription: $SUBSCRIPTION_NAME"
echo ""

# Create resource group
echo -e "${YELLOW}Creating resource group...${NC}"
if az group create --name "$RESOURCE_GROUP" --location "$LOCATION" &> /dev/null; then
    echo -e "${GREEN}✓ Resource group created: $RESOURCE_GROUP${NC}"
else
    echo -e "${GREEN}✓ Resource group already exists: $RESOURCE_GROUP${NC}"
fi
echo ""

# Deploy the template
echo -e "${YELLOW}Deploying Ubuntu VM...${NC}"
echo "This may take several minutes..."
echo ""

DEPLOYMENT_OUTPUT=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters adminSshKey="$(cat "$SSH_KEY_PATH")" \
    --query properties.outputs \
    -o json)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Deployment completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # Extract outputs
    PUBLIC_IP=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.publicIpAddress.value')
    FQDN=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.fqdn.value')
    SSH_COMMAND=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.sshCommand.value')
    
    echo -e "${YELLOW}Connection Information:${NC}"
    echo "  Public IP: $PUBLIC_IP"
    echo "  FQDN: $FQDN"
    echo ""
    echo -e "${YELLOW}SSH Connection:${NC}"
    echo "  $SSH_COMMAND"
    echo ""
    echo -e "${GREEN}To connect to your VM, run:${NC}"
    PRIVATE_KEY_PATH="${SSH_KEY_PATH%.pub}"
    echo "  $SSH_COMMAND -i $PRIVATE_KEY_PATH"
    echo ""
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ Deployment failed${NC}"
    echo -e "${RED}========================================${NC}"
    echo "Please check the error messages above"
    exit 1
fi

echo -e "${YELLOW}To delete all resources when done:${NC}"
echo "  az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo ""
